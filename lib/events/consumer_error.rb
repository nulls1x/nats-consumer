# frozen_string_literal: true

module Events
  # Raising ConsumerError or a subclass from within a consumer
  # results in the message being TERMinated (no redelivery).
  class ConsumerError < StandardError; end
end
