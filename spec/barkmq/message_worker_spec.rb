require 'spec_helper'
require 'barkmq/message_worker'

RSpec.describe BarkMQ::MessageWorker do
  subject { described_class.new }

  describe '#perform' do
    before do
      BarkMQ.subscriber_config do |c|
        c.logger = Logger.new('/tmp/blank.log')
        c.queue_name = 'test-barkmq'
      end
    end

    it 'calls BarkMQ.handle_message' do
      expect(subject).to receive(:topic).and_return('test_topic')
      expect(subject).to receive(:message).and_return('message')
      expect(BarkMQ).to receive(:handle_message).with('test_topic', 'message')
      subject.perform('sqs_message', 'body')
    end
  end

  # describe 'shoryuken_options' do
  #
  # end
end
