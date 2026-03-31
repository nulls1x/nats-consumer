# frozen_string_literal: true

RSpec.describe NatsConsumer::ConsumerStats do
  subject(:stats) { described_class.new(logger:, consumer_name: 'test_consumer') }

  let(:logger) { instance_double(NatsConsumer::Logger, info: nil) }
  let(:msg) { instance_double(NatsConsumer::Message, to_h: { type: 'TestEvent', data: {} }) }

  describe '#track', :freeze_time do
    before { stats.track('events.created', msg, 12.5) }

    it 'logs and tracks processed message' do
      expect(logger).to have_received(:info).with(
        nil,
        include('@subject': 'events.created', '@consumer': 'test_consumer', '@duration': '12.5 ms')
      )
      expect(stats.last_processed_at).to eq(Time.now)
      expect(stats.recent_subjects).to contain_exactly({ subject: 'events.created', duration: 12.5 })
    end
  end

  describe '#increment' do
    it 'increments processed count' do
      expect { stats.increment }.to change(stats, :processed_count).from(0).to(1)
    end
  end
end
