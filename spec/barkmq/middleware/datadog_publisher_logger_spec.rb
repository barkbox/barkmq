require 'spec_helper'

RSpec.describe BarkMQ::Middleware::DatadogPublisherLogger do
  subject { described_class.new(options) }

  let(:statsd) { Datadog::Statsd.new }

  describe '#call' do
    def call
      subject.call('test_topic', 'message', &block)
    end

    describe 'when publisher succeeds' do
      let(:options) { {  logger: Logger.new('/tmp/blank.log'), statsd: statsd } }
      let(:block) { -> {} }

      it 'instrument to statsd' do
        expect(statsd).to receive(:increment).with('barkmq.message.publish', {:tags=>["topic:test_topic"]})
        expect(statsd).to receive(:increment).with('barkmq.message.published', {:tags=>["topic:test_topic"]})
        expect(statsd).to receive(:gauge).with('barkmq.message.publish.time', anything, {:tags=>["topic:test_topic"]})
        call
      end
    end

    describe 'when call fails' do
      let(:options) { { logger: Logger.new('/tmp/blank.log'), statsd: statsd } }
      let(:block) { ->{ raise StandardError, 'test failure' } }

      it 'raises the error' do
        expect { call }.to raise_error(StandardError)
      end
    end
  end
end
