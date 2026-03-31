# frozen_string_literal: true

RSpec.describe NatsConsumer::Worker do
  subject(:worker) { described_class.new(queue, on_replaced:) }

  let(:queue) { instance_double(NatsConsumer::ConsumerQueue, next: nil, done: nil, backoff: nil) }
  let(:on_replaced) { instance_double(Proc, call: nil) }
  let(:consumer) { instance_double(NatsConsumer::BaseConsumer, process: nil, config: { durable_name: 'test' }) }

  describe '#run' do
    context 'when consumer is available' do
      before { allow(queue).to receive(:next).and_return(consumer) }

      it 'processes consumer and marks done' do
        worker.run

        expect(consumer).to have_received(:process)
        expect(queue).to have_received(:done).with(consumer)
      end
    end

    # rubocop:disable RSpec/SubjectStub
    context 'when queue is empty' do
      before { allow(worker).to receive(:sleep) }

      it 'sleeps and does nothing' do
        worker.run

        expect(worker).to have_received(:sleep).with(described_class::IDLE_SLEEP)
        expect(queue).not_to have_received(:done)
      end
    end
    # rubocop:enable RSpec/SubjectStub

    context 'when consumer raises error' do
      before do
        allow(queue).to receive(:next).and_return(consumer)
        allow(consumer).to receive(:process).and_raise(StandardError, 'boom')
      end

      it 'backs off consumer, replaces itself and re-raises' do
        expect { worker.run }.to raise_error(StandardError, 'boom')

        expect(queue).to have_received(:backoff).with(consumer)
        expect(on_replaced).to have_received(:call)
      end
    end
  end
end
