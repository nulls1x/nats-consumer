# frozen_string_literal: true

RSpec.describe NatsConsumer::HandlerList do
  subject(:list) { described_class.new(handlers) }

  let(:handler_instance) { double('handler_instance', call: nil) } # rubocop:disable RSpec/VerifiedDoubles
  let(:handler) { double('handler', new: handler_instance) } # rubocop:disable RSpec/VerifiedDoubles
  let(:handlers) { { 'MockedEvent' => [handler] } }

  describe '#handling?' do
    it { is_expected.to be_handling('MockedEvent') }
    it { is_expected.not_to be_handling('UnknownEvent') }
  end

  describe '#handle' do
    let(:msg) { NatsConsumer::Message.new(type: 'MockedEvent', data: {}) }

    context 'with known event' do
      it 'calls handlers for event' do
        list.handle(msg)

        expect(handler_instance).to have_received(:call).with(msg)
      end
    end

    context 'with unknown event' do
      let(:msg) { NatsConsumer::Message.new(type: 'UnknownEvent', data: {}) }

      it 'ignores the unknown event' do
        expect { list.handle(msg) }.not_to raise_error
      end
    end
  end
end
