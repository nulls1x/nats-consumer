# frozen_string_literal: true

module Events
  class EnsureConsumer
    extend Dry::Initializer

    class Config < Dry::Struct
      attribute :stream_name, Types::String
      attribute :durable_name, Types::String
      attribute :filter_subjects, Types::Array.of(Types::String)
      attribute :deliver_policy, Types::String.default('all')

      def from_existed(cfg)
        cfg.to_h.merge(filter_subjects:, deliver_policy:)
      end

      def for_create
        attributes.except(:stream_name)
      end
    end

    param :jetstream, Types::Interface(:add_consumer, :consumer_info)
    param :config, Types.Constructor(Config)

    def call
      jetstream.add_consumer(stream_name, config.from_existed(current_config))
    rescue NATS::JetStream::Error::ConsumerNotFound
      jetstream.add_consumer(stream_name, config.for_create)
    end

    private

    def stream_name = config.stream_name
    def durable_name = config.durable_name
    def current_config = jetstream.consumer_info(stream_name, durable_name).config
  end
end
