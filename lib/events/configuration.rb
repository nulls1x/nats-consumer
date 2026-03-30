# frozen_string_literal: true

module Events
  class Configuration
    # Array of NATS server URLs, e.g. ["nats://localhost:4222"]
    attr_accessor :servers

    # Redis URL used by Heartbeat
    attr_accessor :redis_url

    # Wraps each message processing call. Use to integrate Chewy or similar:
    #   config.process_wrapper = ->(_msg, &block) { Chewy.strategy(:atomic) { block.call } }
    attr_accessor :process_wrapper

    # Called when a consumer error is reported. Use to integrate Rollbar or similar:
    #   config.error_handler = ->(error, **ctx) { Rollbar.error(error, **ctx) }
    attr_accessor :error_handler

    def initialize
      @servers = []
      @redis_url = nil
      @process_wrapper = ->(_msg, &block) { block.call }
      @error_handler = ->(_error, **_ctx) {}
    end
  end
end
