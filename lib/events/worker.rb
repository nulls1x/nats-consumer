# frozen_string_literal: true

module Events
  class Worker
    IDLE_SLEEP = 5

    def initialize(queue, on_replaced:)
      @queue = queue
      @on_replaced = on_replaced
    end

    def run
      return sleep(IDLE_SLEEP) unless (consumer = queue.next)

      consumer.process
      queue.done(consumer)
    rescue Exception # rubocop:disable Lint/RescueException
      handle_error(consumer)
      raise
    end

    private

    attr_reader :queue, :on_replaced

    def handle_error(consumer)
      queue.backoff(consumer) if consumer
      on_replaced.()
    end
  end
end
