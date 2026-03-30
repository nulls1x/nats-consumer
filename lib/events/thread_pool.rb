# frozen_string_literal: true

module Events
  class ThreadPool
    DEFAULT_POOL_SIZE = 10

    attr_reader :pool_size

    def initialize(connection_builder, pool_size: nil, logger: Events::Logger.new)
      @connection_builder = connection_builder
      @logger = logger
      @pool_size = pool_size || DEFAULT_POOL_SIZE
      @queue = ConsumerQueue.new
      @threads = []
      @mutex = Mutex.new
      @done = false
      @heartbeat = Heartbeat.new(self, logger:)
    end

    def start
      prepare_consumers(connection_builder.())
      pool_size.times { spawn_worker }
      spawn_heartbeat
      logger.info('Pool started', pool_size:, consumers: queue.status.map { it[:name] })
    end

    def stop = @done = true

    def join
      threads.each(&:join)
      heartbeat_thread&.join
    end

    def threads_alive = threads.count(&:alive?)
    def consumer_status = queue.status

    private

    attr_reader :connection_builder, :logger, :queue, :threads, :mutex, :done, :heartbeat, :heartbeat_thread

    def prepare_consumers(connection)
      ConsumersRegistry.each do |cls|
        consumer = cls.new(connection, logger)
        consumer.prepare
        queue.add(consumer, priority: consumer.priority)
      end
    end

    def spawn_heartbeat = @heartbeat_thread = Thread.new { heartbeat.publish until done }

    def spawn_worker
      worker = Worker.new(queue, on_replaced: method(:spawn_worker))

      mutex.synchronize do
        threads.select!(&:alive?)
        threads << Thread.new { worker.run until done }
      end
    end
  end
end
