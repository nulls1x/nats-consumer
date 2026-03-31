# frozen_string_literal: true

require 'time'

module NatsConsumer
  class Message < Dry::Struct
    attribute? :specversion, Types::String.default('1.0')
    attribute?(:id, Types::String.default { SecureRandom.uuid })
    attribute? :source, Types::String.default('atlas.tools')
    attribute? :datacontenttype, Types::String.default('application/json')
    attribute?(:time, Types::Time.constructor { |v| v.is_a?(Time) ? v : Time.parse(v.to_s) }.default { Time.now })

    attribute :data, Types::Hash
    attribute :type, Types::String

    def self.from_json(json)
      new(JSON.parse(json, symbolize_names: true))
    end

    def copy(overrides = {})
      self.class.new(to_h.merge(overrides))
    end
  end
end
