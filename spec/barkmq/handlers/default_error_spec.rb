require 'spec_helper'

RSpec.describe BarkMQ::Handlers::DefaultError do
  subject { described_class.new(options) }

  let(:statsd) { Statsd.new }

  describe '#call' do
    def call
      subject.call('test error')
    end

    describe 'when publisher error happens' do
      let(:options) { { namespace: 'publisher', logger: Logger.new('/tmp/blank.log'), statsd: statsd } }

      it 'instrument to statsd' do
        expect(statsd).to receive(:increment).with('barkmq.message.publisher.error', {:tags=>["category:publisher"]})
        expect(statsd).to receive(:event).with("BarkMQ publisher error.", anything, anything)
        expect(Circuitry).to receive(:flush)
        call
      end
    end

    describe 'when subscriber error happens' do
      let(:options) { { namespace: 'subscriber', logger: Logger.new('/tmp/blank.log'), statsd: statsd } }

      it 'instrument to statsd' do
        expect(statsd).to receive(:increment).with('barkmq.message.subscriber.error', {:tags=>["category:subscriber"]})
        expect(statsd).to receive(:event).with("BarkMQ subscriber error.", anything, anything)
        call
      end
    end
  end
end
