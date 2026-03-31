# frozen_string_literal: true

module NatsConsumer
  # Raising RetriableError from within a consumer NAKs the message
  # so the server will redeliver it.
  class RetriableError < StandardError; end
end
