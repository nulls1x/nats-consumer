# frozen_string_literal: true

RSpec.describe NatsConsumer::ConsumerQueue do
  subject(:queue) { described_class.new }

  let(:consumer1) { instance_double(NatsConsumer::BaseConsumer, durable_name: 'consumer1') }
  let(:consumer2) { instance_double(NatsConsumer::BaseConsumer, durable_name: 'consumer2') }

  describe '#next' do
    context 'when consumers are available' do
      before do
        queue.add(consumer1)
        queue.add(consumer2)
      end

      it 'returns available consumers and skips in_progress' do
        expect(queue.next).not_to be_nil
        expect(queue.next).not_to be_nil
        expect(queue.next).to be_nil
      end
    end

    context 'when consumer is stale' do
      before { queue.add(consumer1) }

      it 'resets and makes it available again' do
        queue.next
        Timecop.travel(NatsConsumer::QueueEntry::STALE_THRESHOLD + 1)

        expect(queue.next).to eq(consumer1)
      end
    end
  end

  describe '#done' do
    before do
      queue.add(consumer1)
      queue.add(consumer2)
    end

    it 'makes consumer available again' do
      queue.next
      queue.next
      queue.done(consumer1)

      expect(queue.next).to eq(consumer1)
    end
  end

  describe '#backoff' do
    before { queue.add(consumer1) }

    context 'when within backoff period' do
      it 'skips the consumer' do
        queue.backoff(consumer1)

        expect(queue.next).to be_nil
      end
    end

    context 'when backoff period expired' do
      it 'makes consumer available again' do
        queue.backoff(consumer1)
        Timecop.travel(NatsConsumer::QueueEntry::BACKOFF_PERIOD + 1)

        expect(queue.next).to eq(consumer1)
      end
    end
  end
end
