# frozen_string_literal: true

module Events
  class Heartbeat
    REDIS_KEY = 'nats:consumer:status'
    INTERVAL = 5
    TTL = 3600

    def initialize(pool, logger: Events::Logger.new)
      @pool = pool
      @logger = logger
    end

    def publish
      redis.set(REDIS_KEY, status.to_json, ex: TTL)
      sleep INTERVAL
    rescue StandardError => e
      logger.error(e, context: 'heartbeat')
      sleep INTERVAL
    end

    private

    attr_reader :pool, :logger

    def pool_size = pool.pool_size
    def threads_alive = pool.threads_alive
    def consumer_status = pool.consumer_status

    def status = { pool_size:, threads_alive:, rss_mb:, consumers: consumer_status }
    def rss_mb = (`ps -o rss= -p #{Process.pid}`.to_f / 1024).round(1)

    def redis = @redis ||= Redis.new(url: Events.config.redis_url)
  end
end
