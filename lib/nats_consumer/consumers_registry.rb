# frozen_string_literal: true

module NatsConsumer
  module ConsumersRegistry
    extend Enumerable

    class Registry
      def initialize
        @consumers = Set.new
      end

      def add(cls)
        consumers << cls
      end

      attr_reader :consumers

      def each(&block) = consumers.each(&block)
    end

    class << self
      def add(cls) = registry.add(cls)

      def each(&block) = registry.consumers.each(&block)

      def clear
        remove_instance_variable(:@registry) if instance_variable_defined?(:@registry)
      end

      private

      def registry = @registry ||= Registry.new
    end
  end
end
