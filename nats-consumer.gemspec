# frozen_string_literal: true

require_relative 'lib/nats_consumer/version'

Gem::Specification.new do |spec|
  spec.name = 'nats-consumer'
  spec.version = NatsConsumer::VERSION
  spec.authors = ['nulls1x']
  spec.summary = 'NATS JetStream pull consumer framework'
  spec.homepage = 'https://github.com/nulls1x/nats-consumer'
  spec.license = 'LGPL-3.0'

  spec.required_ruby_version = '>= 3.2'

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']

  spec.add_dependency 'dry-initializer', '~> 3.1'
  spec.add_dependency 'dry-struct', '~> 1.6'
  spec.add_dependency 'dry-types', '~> 1.7'
  spec.add_dependency 'nats-pure', '~> 2.4'
  spec.add_dependency 'redis', '>= 4.0'
end
