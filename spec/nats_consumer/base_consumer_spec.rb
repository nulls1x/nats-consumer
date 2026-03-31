# frozen_string_literal: true

RSpec.describe NatsConsumer::BaseConsumer do
  subject(:consumer) { consumer_cls.new(conn, logger) }

  let(:consumer_cls) do
    Class.new(NatsConsumer::BaseConsumer) do
      attr_reader :messages

      def initialize(...)
        super
        @messages = []
      end

      def config
        {
          stream_name: 'example_stream',
          durable_name: 'example_consumer',
          filter_subjects: ['examples.created']
        }
      end

      def process_message(msg)
        @messages << msg
      end
    end
  end
  let(:conn) { instance_double(NATS::Client, jetstream: js) }
  let(:js) { instance_double(NATS::JetStream, pull_subscribe: subscription) }
  let(:ensure_consumer) { instance_double(NatsConsumer::EnsureConsumer, call: nil) }
  let(:subscription) { double('NATS::JetStream::PullSubscription', fetch: [msg]) } # rubocop:disable RSpec/VerifiedDoubles
  let(:msg) { nil }
  let(:logger) { instance_double(NatsConsumer::Logger, info: nil, error: nil) }

  before do
    stub_const('ExampleConsumer', consumer_cls)
  end

  describe '#prepare' do
    before do
      allow(NatsConsumer::EnsureConsumer).to receive_messages(new: ensure_consumer)

      consumer.prepare
    end

    it 'ensures consumer is configured' do
      expect(ensure_consumer).to have_received(:call)
    end

    it 'subsribes to the stream' do
      expect(js).to have_received(:pull_subscribe).with(nil, 'example_consumer', stream: 'example_stream')
    end
  end

  describe '#process_message' do
    let(:conn) { NATS.connect(servers: NatsConsumer.config.servers) }
    let(:js) { conn.jetstream }

    let(:msg) do
      {
        id: '4b16e50e-f067-4209-b656-a7cfeecbd88c',
        source: 'atlas',
        time: '2024-04-17T13:01:23+00:00',
        type: 'Events::Examples::ExampleCreated',
        datacontenttype: 'application/json',
        data: {
          account_id: 777,
          account_fullname: 'John Doe',
          account_role: 'agent',
          lead_id: 999
        }
      }
    end

    before do
      js.add_stream(name: 'example_stream', subjects: ['examples.>'], storage: :memory)
      js.publish('examples.created', msg.to_json)

      consumer.prepare
      consumer.process
    end

    after do
      js.delete_consumer('example_stream', 'example_consumer')
      js.delete_stream('example_stream')
    end

    it 'fetches message and passes to proccess event hook' do
      expect(consumer.messages).to contain_exactly(
        have_attributes(
          type: 'Events::Examples::ExampleCreated',
          time: Time.parse('2024-04-17T13:01:23+00:00'),
          data: {
            account_id: 777,
            account_fullname: 'John Doe',
            account_role: 'agent',
            lead_id: 999
          }
        )
      )

      expect(logger).to have_received(:info).with(
        nil,
        include(:@subject => 'examples.created', :@consumer => 'example_consumer')
      )
    end
  end

  describe '#process errors' do
    before do
      allow(NatsConsumer::EnsureConsumer).to receive_messages(new: ensure_consumer)

      consumer.prepare
    end

    context 'with timeout' do
      before do
        allow(subscription).to receive(:fetch).and_raise(NATS::IO::Timeout)
      end

      it 'does not crash on timeout' do
        expect { consumer.process }.not_to raise_error
      end
    end

    context 'with invalid JSON' do
      let(:error_handler) { instance_double(Proc, call: nil) }
      let(:msg) { instance_double(NATS::Msg, data: 'invalid json', subject: 'subj', ack: nil, nak: nil, term: nil) }

      before do
        allow(subscription).to receive_messages(fetch: [msg])
        NatsConsumer.config.error_handler = error_handler.method(:call)

        consumer.process
      end

      after do
        NatsConsumer.config.error_handler = ->(_error, **_ctx) {}
      end

      it 'logs the error' do
        expect(logger).to have_received(:error).with(
          kind_of(JSON::ParserError),
          '@consumer': 'example_consumer',
          '@subject': 'subj',
          msg: 'invalid json'
        )

        expect(error_handler).to have_received(:call).with(
          kind_of(JSON::ParserError),
          '@consumer': 'example_consumer',
          '@subject': 'subj',
          msg: 'invalid json'
        )
      end

      it 'terms the message' do
        expect(msg).not_to have_received(:ack)
        expect(msg).not_to have_received(:nak)
        expect(msg).to have_received(:term)
      end
    end

    context 'with retriable error' do
      let(:consumer_cls) do
        Class.new(NatsConsumer::BaseConsumer) do
          def config = { durable_name: 'retriable_consumer', stream_name: 'test_stream' }
          def process_message(_msg) = raise NatsConsumer::RetriableError
        end
      end

      let(:msg) do
        instance_double(
          NATS::Msg,
          data: { type: 'Examples::Created', data: {} }.to_json,
          subject: 'subj',
          ack: nil, nak: nil, term: nil
        )
      end

      before do
        consumer.process
      end

      it 'naks message' do
        expect(msg).not_to have_received(:ack)
        expect(msg).to have_received(:nak)
        expect(msg).not_to have_received(:term)
      end
    end
  end
end
