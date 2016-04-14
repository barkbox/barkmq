require 'spec_helper'
require 'barkmq/message_worker'

RSpec.describe BarkMQ::MessageWorker do
  subject { described_class.new }

  describe '#perform' do

    it 'calls BarkMQ.handle_message' do
      expect(subject).to receive(:topic).and_return('test_topic')
      expect(subject).to receive(:message).and_return('message')
      expect(BarkMQ).to receive(:handle_message).with('test_topic', 'message')
      subject.perform('sqs_message', 'body')
    end
  end

  describe '.shoryuken_options' do
    it 'sets queue name from BarkMQ.subscriber_config' do
      BarkMQ.subscriber_config do |c|
        c.queue_name = 'test-barkmq'
      end
      load 'barkmq/message_worker.rb'
      expect(subject.class.get_shoryuken_options['queue']).to eq('test-barkmq')
    end

    it 'sets queue name from ENV[\'BARKMQ_QUEUE\']' do
      cached_barkmq_queue = ENV['BARKMQ_QUEUE']
      ENV['BARKMQ_QUEUE'] = 'test-env-barkmq'
      load 'barkmq/message_worker.rb'
      expect(subject.class.get_shoryuken_options['queue']).to eq('test-env-barkmq')
      ENV['BARKMQ_QUEUE'] = cached_barkmq_queue
    end
  end
end
