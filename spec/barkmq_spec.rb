require 'spec_helper'

describe BarkMQ, type: :model do
  subject { described_class }

  shared_examples_for 'a configuration method' do |method|
    it 'returns a configuration object' do
      expect(subject.send(method)).to be_a BarkMQ::Config::Shared
    end

    it 'always returns the same object' do
      expect(subject.send(method)).to be subject.send(method)
    end

    it 'accepts a block' do
      expect {
        subject.send(method) { |c| c.topic_namespace = 'foo' }
      }.to change { subject.send(method).topic_namespace }.to('foo')
    end
  end

  describe '.subscriber_config' do
    it_behaves_like 'a configuration method', :subscriber_config
  end

  describe '.publisher_config' do
    it_behaves_like 'a configuration method', :publisher_config
  end

  describe '.publish' do
    it 'to publish through async publisher' do
      BarkMQ.publisher_config
      options = {}
      expect(Celluloid::Actor[:publisher]).to receive_message_chain(:async, :publish).with('test_topic', 'message', options)
      BarkMQ.publish('test_topic', 'message', options)
    end
  end

  describe '.subscribe!' do
    before do
      BarkMQ.subscriber_config do |c|
        c.topic_namespace = 'barkmq-test'
      end
      BarkMQ.sub_config.topic_names = []
      BarkMQ.sub_config.clear_handlers
    end

    it 'handles message with handler' do
      $topics = 'topic_single_string'

      class NewSubscriberWorker
        include BarkMQ::Subscriber

        barkmq_subscriber_options topics: $topics

        def perform topic, message
        end
      end

      expect(NewSubscriberWorker).to receive(:new).and_return(NewSubscriberWorker.new)
      expect_any_instance_of(NewSubscriberWorker).to receive(:perform).with('barkmq-test-topic_single_string', 'message')
      BarkMQ.handle_message('barkmq-test-topic_single_string', 'message')
    end

    it 'raises error on message without handler' do
      expect{ BarkMQ.handle_message('test_topic_single_string', 'message') }.to raise_error(BarkMQ::HandlerNotFound)
    end

    it 'raises error on message with unimplemented handler' do
      $topics = 'test_topic_single_string'

      class UnimplementedSubscriberWorker
        include BarkMQ::Subscriber

        barkmq_subscriber_options topics: $topics
      end

      expect{ BarkMQ.handle_message('barkmq-test-test_topic_single_string', 'message') }.to raise_error(BarkMQ::SubscriberNotImplemented)
    end
  end

end
