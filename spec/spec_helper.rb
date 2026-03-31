# frozen_string_literal: true

require 'nats_consumer'
require 'timecop'

NatsConsumer.configure do |config|
  config.servers = ENV.fetch('NATS_SERVERS', 'nats://localhost:4222').split(',')
end

RSpec.configure do |config|
  config.around(:each, :freeze_time) do |example|
    Timecop.freeze { example.run }
  end
end
