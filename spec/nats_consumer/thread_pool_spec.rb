# frozen_string_literal: true

RSpec.describe NatsConsumer::ThreadPool do
  subject(:pool) { described_class.new(connection_builder, pool_size: 2, logger:) }

  let(:connection_builder) { proc { connection } }
  let(:connection) { instance_double(NATS::Client) }
  let(:logger) { instance_double(NatsConsumer::Logger, info: nil, error: nil) }
  let(:queue) { instance_double(NatsConsumer::ConsumerQueue, add: nil, status: []) }

  let(:consumer) { instance_double(NatsConsumer::BaseConsumer, prepare: nil, priority: 1, config: { durable_name: 'test' }) }
  let(:consumer_cls) { class_double(NatsConsumer::BaseConsumer, new: consumer) }
  let(:worker) { instance_double(NatsConsumer::Worker) }
  let(:thread) { instance_double(Thread, join: nil, alive?: true) }
  let(:heartbeat) { instance_double(NatsConsumer::Heartbeat, publish: nil) }

  before do
    allow(NatsConsumer::ConsumerQueue).to receive(:new).and_return(queue)
    allow(NatsConsumer::ConsumersRegistry).to receive(:each).and_yield(consumer_cls)
    allow(NatsConsumer::Heartbeat).to receive(:new).and_return(heartbeat)
    allow(NatsConsumer::Worker).to receive(:new).and_return(worker)
    allow(worker).to receive(:run) { pool.stop }
    allow(Thread).to receive(:new).and_yield.and_return(thread)
  end

  describe '#start' do
    it 'prepares consumers, adds to queue, creates workers and runs them' do
      pool.start

      expect(consumer_cls).to have_received(:new).with(connection, logger)
      expect(consumer).to have_received(:prepare)
      expect(queue).to have_received(:add).with(consumer, priority: 1)

      expect(NatsConsumer::Heartbeat).to have_received(:new).with(pool, logger:)
      expect(NatsConsumer::Worker).to have_received(:new).with(queue, on_replaced: kind_of(Method)).twice
      expect(worker).to have_received(:run).once
    end
  end
end
