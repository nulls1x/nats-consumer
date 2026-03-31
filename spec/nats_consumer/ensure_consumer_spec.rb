# frozen_string_literal: true

RSpec.describe NatsConsumer::EnsureConsumer do
  subject(:service) { described_class.new(js, config) }

  def js = @js ||= NATS.connect(servers: NatsConsumer.config.servers).jetstream

  let(:stream_name) { 'events_stream' }
  let(:durable_name) { 'events_consumer' }
  let(:config) { { stream_name:, durable_name:, filter_subjects: } }

  context 'when consumer not exists' do
    before { js.add_stream(name: stream_name, subjects: ['events.>'], storage: :memory) }

    after do
      js.delete_consumer(stream_name, durable_name)
      js.delete_stream(stream_name)
    end

    let(:filter_subjects) { ['event.created', 'event.deleted'] }

    it 'creates consumer' do
      service.()

      expect(js.consumer_info(stream_name, durable_name)).to have_attributes(
        stream_name:,
        config: have_attributes(durable_name:, filter_subjects:)
      )
    end
  end

  context 'when consumer exists' do
    before do
      js.add_stream(name: stream_name, subjects: ['events.>'], storage: :memory)
      js.add_consumer(stream_name, durable_name:, filter_subjects: ['event.created', 'event.deleted'])
    end

    after do
      js.delete_consumer(stream_name, durable_name)
      js.delete_stream(stream_name)
    end

    let(:filter_subjects) { ['event.created', 'event.deleted', 'event.handled'] }

    it 'updates consumer' do
      service.()

      expect(js.consumer_info(stream_name, durable_name)).to have_attributes(
        config: have_attributes(filter_subjects:)
      )
    end
  end
end
