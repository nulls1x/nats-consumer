# frozen_string_literal: true

module Events
  class ConsumerStats
    RECENT_SUBJECTS_LIMIT = 10

    attr_reader :last_processed_at, :recent_subjects, :processed_count

    def initialize(logger:, consumer_name:)
      @logger = logger
      @consumer_name = consumer_name
      @last_processed_at = nil
      @recent_subjects = []
      @processed_count = 0
    end

    def track(subject, msg, duration)
      log_processed(subject, msg, duration)
      track_subject(subject, duration)
      self.last_processed_at = Time.now
    end

    def increment = self.processed_count += 1

    private

    attr_accessor :logger, :consumer_name
    attr_writer :last_processed_at, :recent_subjects, :processed_count

    def log_processed(subject, msg, duration)
      logger.info nil, msg.to_h.merge('@subject': subject, '@consumer': consumer_name, '@duration': "#{duration} ms")
    end

    def track_subject(subject, duration)
      self.recent_subjects = [*recent_subjects, { subject:, duration: }].last(RECENT_SUBJECTS_LIMIT)
    end
  end
end
