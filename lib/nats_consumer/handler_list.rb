# frozen_string_literal: true

module NatsConsumer
  class HandlerList
    def initialize(handlers)
      @handlers = handlers
    end

    def handling?(msg_type) = handlers.key?(msg_type)

    def handle(msg)
      return unless handling?(msg.type)

      pass_to_handlers(msg)
    end

    private

    attr_reader :handlers

    def pass_to_handlers(msg) = handlers[msg.type].each { _1.new.(msg) }
  end
end
