# frozen_string_literal: true

module Events
  class ConsumerQueue
    def initialize
      @entries = {}
      @rotation = []
      @mutex = Mutex.new
    end

    def add(consumer, priority: 1)
      entry = QueueEntry.new(consumer)
      @entries[consumer] = entry
      priority.times { @rotation << entry }
    end

    def next
      @mutex.synchronize do
        entry = find_available
        next unless entry

        entry.start!
        entry.consumer
      end
    end

    def done(consumer) = @mutex.synchronize { entries[consumer].release! }
    def backoff(consumer) = @mutex.synchronize { entries[consumer].backoff! }

    def status = @mutex.synchronize { consumers.map { consumer_status(it) } }

    private

    attr_reader :entries, :rotation, :mutex

    def consumers = entries.values.map(&:consumer)
    def find_available = rotation.shuffle.find(&:available?)

    def consumer_status(consumer)
      {
        name: consumer.durable_name,
        processed_count: consumer.processed_count,
        recent_events: consumer.recent_subjects.dup,
        last_processed_at: consumer.last_processed_at&.iso8601
      }
    end
  end
end
