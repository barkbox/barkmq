require 'spec_helper'

RSpec.describe 'BarkMQ::Subscriber' do

  describe '.barkmq_subscriber_options' do

    before do
      BarkMQ.sub_config.topic_names = []
      BarkMQ.sub_config.clear_handlers
    end

    it 'accepts a single topic string' do
      $topics = 'test_topic_single_string'

      class NewSubscriberWorker
        include BarkMQ::Subscriber
        barkmq_subscriber_options topics: $topics
      end

      expect(BarkMQ.sub_config.topic_names).to eq([$topics])
      expect(BarkMQ.sub_config.handlers).to eq({ $topics => NewSubscriberWorker })
    end

    it 'accepts a single topic array' do
      $topics = ['test_topic_single_array']

      class NewSubscriberWorker
        include BarkMQ::Subscriber
        barkmq_subscriber_options topics: $topics
      end

      expect(BarkMQ.sub_config.topic_names).to eq($topics)
      expect(BarkMQ.sub_config.handlers).to eq(Hash[$topics.collect{ |t| [t, NewSubscriberWorker] }])
    end

    it 'accepts a multiple topic array' do
      $topics = ['test_topic_1', 'test_topic_2']

      class NewSubscriberWorker
        include BarkMQ::Subscriber
        barkmq_subscriber_options topics: $topics
      end

      expect(BarkMQ.sub_config.topic_names).to eq($topics)
      expect(BarkMQ.sub_config.handlers).to eq(Hash[$topics.collect{ |t| [t, NewSubscriberWorker] }])
    end

  end

end
