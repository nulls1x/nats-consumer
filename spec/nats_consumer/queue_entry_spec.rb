# frozen_string_literal: true

RSpec.describe NatsConsumer::QueueEntry do
  subject(:entry) { described_class.new(consumer) }

  let(:consumer) { instance_double(NatsConsumer::BaseConsumer) }

  describe '#new' do
    it 'defaults to available state' do
      expect(entry).to be_available
    end
  end

  describe '#start!' do
    it 'transitions to in_progress' do
      entry.start!

      expect(entry.state).to eq(:in_progress)
      expect(entry).not_to be_available
    end
  end

  describe '#release!' do
    it 'transitions back to available' do
      entry.start!
      entry.release!

      expect(entry.state).to eq(:available)
      expect(entry).to be_available
    end
  end

  describe '#backoff!' do
    it 'transitions to backoff' do
      entry.backoff!

      expect(entry.state).to eq(:backoff)
      expect(entry).not_to be_available
    end
  end

  describe '#available?' do
    context 'when backoff period expired' do
      it 'becomes available again' do
        entry.backoff!
        Timecop.travel(described_class::BACKOFF_PERIOD + 1)

        expect(entry).to be_available
      end
    end

    context 'when in_progress and stale' do
      it 'becomes available again' do
        entry.start!
        Timecop.travel(described_class::STALE_THRESHOLD + 1)

        expect(entry).to be_available
      end
    end
  end
end
