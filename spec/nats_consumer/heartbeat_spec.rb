# frozen_string_literal: true

# rubocop:disable RSpec/SubjectStub
RSpec.describe NatsConsumer::Heartbeat do
  subject(:heartbeat) { described_class.new(pool, logger:) }

  let(:pool) { instance_double(NatsConsumer::ThreadPool, pool_size: 4, threads_alive: 3, consumer_status: []) }
  let(:logger) { instance_double(NatsConsumer::Logger, info: nil, error: nil) }
  let(:redis) { instance_double(Redis, set: nil) }

  before do
    allow(Redis).to receive(:new).and_return(redis)
    allow(heartbeat).to receive_messages(sleep: nil, rss_mb: 128.5)
  end

  describe '#publish' do
    it 'writes status to redis and sleeps' do
      heartbeat.publish

      expect(redis).to have_received(:set).with(
        described_class::REDIS_KEY,
        { pool_size: 4, threads_alive: 3, rss_mb: 128.5, consumers: [] }.to_json,
        ex: described_class::TTL
      )
      expect(heartbeat).to have_received(:sleep).with(described_class::INTERVAL)
    end

    context 'when redis raises an error' do
      before { allow(redis).to receive(:set).and_raise(Redis::ConnectionError) }

      it 'logs error and sleeps' do
        heartbeat.publish

        expect(logger).to have_received(:error).with(kind_of(Redis::ConnectionError), context: 'heartbeat')
        expect(heartbeat).to have_received(:sleep).with(described_class::INTERVAL)
      end
    end
  end
end
# rubocop:enable RSpec/SubjectStub
