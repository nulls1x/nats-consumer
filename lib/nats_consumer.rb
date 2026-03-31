# frozen_string_literal: true

require 'json'
require 'set'
require 'securerandom'
require 'redis'
require 'nats/client'
require 'dry/struct'
require 'dry/initializer'

require_relative 'nats_consumer/version'
require_relative 'nats_consumer/types'
require_relative 'nats_consumer/configuration'
require_relative 'nats_consumer/consumer_error'
require_relative 'nats_consumer/retriable_error'
require_relative 'nats_consumer/message'
require_relative 'nats_consumer/logger'
require_relative 'nats_consumer/consumers_registry'
require_relative 'nats_consumer/consumer_stats'
require_relative 'nats_consumer/handler_list'
require_relative 'nats_consumer/queue_entry'
require_relative 'nats_consumer/consumer_queue'
require_relative 'nats_consumer/ensure_consumer'
require_relative 'nats_consumer/heartbeat'
require_relative 'nats_consumer/base_consumer'
require_relative 'nats_consumer/worker'
require_relative 'nats_consumer/thread_pool'

module NatsConsumer
  class << self
    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end
  end
end
