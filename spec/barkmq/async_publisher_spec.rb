require 'spec_helper'

RSpec.describe BarkMQ::AsyncPublisher do

  subject { described_class.new }

  let(:topic_name) { 'test_topic' }
  let(:message) { 'test_message' }

  before do
    BarkMQ.publisher_config do |c|
      c.logger = Logger.new('/tmp/blank.log')
    end
  end

  describe '#publish' do
    def publish options={}
      subject.publish(topic_name, message, options)
    end

    it 'calls _publish' do
      expect(subject.wrapped_object).to receive(:_publish).with(topic_name, message).and_call_original
      publish
    end

    it 'calls middleware' do
      expect(subject.wrapped_object).to receive_message_chain(:middleware, :call)
      publish
    end

    it 'calls error handler' do
      subject.wrapped_object.instance_eval do
        def _publish topic_arn, message
          raise 'test'
        end
      end
      expect(subject.wrapped_object).to receive_message_chain(:error_handler, :call).with(topic_name, RuntimeError)
      publish
    end

    it 'calls timeout error' do
      subject.wrapped_object.instance_eval do
        def _publish topic_arn, message
          sleep(2)
        end
      end
      expect(subject.wrapped_object).to receive_message_chain(:error_handler, :call).with(topic_name, BarkMQ::PublishTimeout)
      publish({ timeout: 1 })
    end

    it 'retries connection error' do
      subject.wrapped_object.instance_eval do
        def _publish topic_arn, message
          raise ::Aws::SNS::Errors::InternalFailure.new('test', 'error')
        end
      end
      expect(subject.wrapped_object).to receive(:_publish).and_call_original.exactly(3).times
      publish
    end
  end

end
