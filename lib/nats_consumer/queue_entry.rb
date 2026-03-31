# frozen_string_literal: true

module NatsConsumer
  class QueueEntry
    BACKOFF_PERIOD = 900  # 15 minutes in seconds
    STALE_THRESHOLD = 300 # 5 minutes in seconds

    attr_reader :state, :since, :consumer

    def initialize(consumer)
      @consumer = consumer
      @state = :available
      @since = nil
    end

    def available?
      case state
      when :available then true
      when :in_progress then stale?
      when :backoff then cooled_off?
      else false
      end
    end

    def start!
      self.state = :in_progress
      self.since = Time.now
    end

    def release!
      self.state = :available
      self.since = nil
    end

    def backoff!
      self.state = :backoff
      self.since = Time.now
    end

    private

    attr_writer :state, :since

    def stale? = since && Time.now - since > STALE_THRESHOLD
    def cooled_off? = since && Time.now - since > BACKOFF_PERIOD
  end
end
