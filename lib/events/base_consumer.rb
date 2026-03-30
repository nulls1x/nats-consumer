# frozen_string_literal: true

module Events
  class BaseConsumer
    RECONNECTION_PERIOD = 5

    attr_reader :logger, :connection, :stats

    def initialize(connection, logger = Logger.new)
      @logger = logger
      @connection = connection
      @subscription = nil
      @stats = ConsumerStats.new(logger:, consumer_name: durable_name)
    end

    def prepare
      logger.info('Preparing', config:)

      jetstream = connection.jetstream
      EnsureConsumer.new(jetstream, config).()
      @subscription = jetstream.pull_subscribe(nil, durable_name, stream: stream_name)
    end

    def process
      process_one
    rescue NATS::IO::Timeout
      # No new messages — worker will cycle to next consumer.
    rescue SocketError
      # Connection issue — give NATS client time to reconnect.
      sleep RECONNECTION_PERIOD
    end

    def last_processed_at = stats.last_processed_at
    def recent_subjects = stats.recent_subjects
    def processed_count = stats.processed_count

    def durable_name = config[:durable_name] || raise(NotImplementedError)
    def stream_name = config[:stream_name] || raise(NotImplementedError)
    def priority = config.fetch(:priority, 1)

    def config = raise NotImplementedError

    private

    def process_one
      next_message(on_success: -> { stats.increment }) do |raw_msg|
        msg = Message.from_json(raw_msg.data)
        duration = measure_ms { Events.config.process_wrapper.(msg) { process_message(msg) } }
        stats.track(raw_msg.subject, msg, duration)
      end
    end

    def next_message(on_success: nil)
      raw_msg = @subscription.fetch.first
      yield raw_msg
      raw_msg.ack
      on_success&.()
    rescue Dry::Struct::Error, JSON::ParserError, ConsumerError => e
      raw_msg.term
      log_error(raw_msg, e)
    rescue RetriableError
      raw_msg.nak
    end

    def process_message(_msg) = raise NotImplementedError

    def measure_ms
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
      yield
      (Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - started_at).round(1)
    end

    def log_error(raw_msg, error)
      context = { '@consumer': durable_name, '@subject': raw_msg.subject, msg: raw_msg.data }
      logger.error(error, context)
      Events.config.error_handler.(error, **context)
    end
  end
end
