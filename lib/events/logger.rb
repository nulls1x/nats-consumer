# frozen_string_literal: true

module Events
  class Logger
    def initialize(logger = ::Logger.new($stdout))
      @logger = logger
    end

    def info(msg, context = {})
      @logger.info log_data('INFO', context.merge(msg:))
    end

    def error(msg, context = {})
      @logger.error log_data('ERROR', context.merge(msg:))
    end

    private

    def log_data(level, context)
      {
        '@timestamp': Time.now.strftime('%Y-%m-%dT%H:%M:%S.%3N%z'),
        '@level': level
      }.merge(context).compact.to_json
    end
  end
end
