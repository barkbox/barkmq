require 'spec_helper'

RSpec.describe BarkMQ::Handlers::DefaultError do
  subject { described_class.new(options) }

  let(:statsd) { BarkMQ::Statsd.new }

  describe '#call' do
    def call
      subject.call('test_topic', 'test error')
    end

    describe 'when publisher error happens' do
      let(:options) { { namespace: 'publisher', logger: Logger.new('/tmp/blank.log'), statsd: statsd } }

      it 'instrument to statsd' do
        expect(statsd).to receive(:increment).with('barkmq.message.publisher.error', {:tags=>["topic_name:test_topic"]})
        expect(statsd).to receive(:event).with("BarkMQ error. namespace=\"publisher\"", anything, anything)
        call
      end
    end

    describe 'when subscriber error happens' do
      let(:options) { { namespace: 'subscriber', logger: Logger.new('/tmp/blank.log'), statsd: statsd } }

      it 'instrument to statsd' do
        expect(statsd).to receive(:increment).with('barkmq.message.subscriber.error', {:tags=>["topic_name:test_topic"]})
        expect(statsd).to receive(:event).with("BarkMQ error. namespace=\"subscriber\"", anything, anything)
        call
      end
    end
  end
end
