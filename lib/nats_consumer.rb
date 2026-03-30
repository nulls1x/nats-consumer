# frozen_string_literal: true

require 'json'
require 'set'
require 'securerandom'
require 'redis'
require 'nats/client'
require 'dry-struct'
require 'dry-initializer'

require_relative 'nats_consumer/version'
require_relative 'events/types'
require_relative 'events/configuration'
require_relative 'events/consumer_error'
require_relative 'events/retriable_error'
require_relative 'events/message'
require_relative 'events/logger'
require_relative 'events/consumers_registry'
require_relative 'events/consumer_stats'
require_relative 'events/handler_list'
require_relative 'events/queue_entry'
require_relative 'events/consumer_queue'
require_relative 'events/ensure_consumer'
require_relative 'events/heartbeat'
require_relative 'events/base_consumer'
require_relative 'events/worker'
require_relative 'events/thread_pool'

module Events
  class << self
    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end
  end
end
