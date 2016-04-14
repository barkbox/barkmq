require 'spec_helper'
require 'barkmq/message_worker'

RSpec.describe BarkMQ::Middleware::DatadogSubscriberLogger do
  subject { described_class.new }

  let(:message_worker) { BarkMQ::MessageWorker.new }
  let(:queue) { 'test_queue' }
  let(:sqs_message) { double(message_id: '123', receipt_handle: 'abc', body: body.to_json) }
  let(:statsd) { Statsd.new }
  let(:body) { { "TopicArn" => "arn:aws:sns:us-east-1:123456789012:test_topic", "Message" => "{\"foo\":\"bar\"}" } }

  describe '#call' do
    before do
      BarkMQ.subscriber_config do |c|
        c.logger = Logger.new('/tmp/blank.log')
      end
    end

    def call
      subject.call(message_worker, queue, sqs_message, body, &block)
    end

    describe 'when publisher succeeds' do
      let(:block) { -> {} }

      it 'sets topic and message' do
        call
        expect(message_worker.topic).to eq('test_topic')
        expect(message_worker.message).to eq({"foo" => "bar"})
      end

      it 'instrument to statsd' do
        expect(subject.statsd).to receive(:increment).with('barkmq.message.received', {:tags=>["topic:test_topic"]})
        expect(subject.statsd).to receive(:increment).with('barkmq.message.processed', {:tags=>["topic:test_topic"]})
        expect(subject.statsd).to receive(:gauge).with('barkmq.message.process.time', anything, {:tags=>["topic:test_topic"]})
        call
      end
    end

    describe 'when call fails' do
      let(:block) { ->{ raise StandardError, 'test failure' } }

      it 'sets topic and message' do
        expect { call }.to raise_error(StandardError)
        expect(message_worker.topic).to eq('test_topic')
        expect(message_worker.message).to eq({"foo" => "bar"})
      end

      it 'raises the error' do
        expect { call }.to raise_error(StandardError)
      end
    end
  end
end
