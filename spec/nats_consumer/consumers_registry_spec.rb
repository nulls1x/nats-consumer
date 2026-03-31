# frozen_string_literal: true

RSpec.describe NatsConsumer::ConsumersRegistry do
  subject(:registry) { described_class }

  before { described_class.clear }

  let(:consumer_cls) { Class.new(NatsConsumer::BaseConsumer) }

  it 'enumerable' do
    expect(registry.singleton_class.ancestors).to include(Enumerable)
  end

  describe '#add' do
    it 'adds consumer class to registry' do
      registry.add(consumer_cls)

      expect(registry.to_a).to contain_exactly(consumer_cls)
    end

    context 'when adding same class few times' do
      it 'stays idempotent' do
        registry.add(consumer_cls)
        registry.add(consumer_cls)

        expect(registry.to_a).to contain_exactly(consumer_cls)
      end
    end
  end
end
