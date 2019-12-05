require 'spec_helper'

RSpec.describe BarkMQ::Publisher do

  before do
    BarkMQ.publisher_config do |c|
      c.topic_namespace = 'test-barkmq'
      c.redis = MockRedis.new
      c.topic_arn_cache_key = 'barkmq'
    end
  end

  describe '.publish' do
    let(:topic_name) { 'queue-name-1' }
    let(:topic_arn) { 'queue-name-1-arn' }
    let(:message) { 'example-message' }

    it 'should handle publish to sns by using topic name and message, and cache the topic arn' do
      expect(Shoryuken::Client.sns).to receive(:create_topic).and_return(
        double('topic_arn', topic_arn: topic_arn))
      expect(Shoryuken::Client.sns).to receive(:publish).with(
        topic_arn: topic_arn, message: message)

      BarkMQ::Publisher.publish(topic_name, message)

      expect(BarkMQ.publisher_config.redis.hget('barkmq', topic_name)).to eq(topic_arn)
    end
  end

  describe '.model_name' do
    it 'PORO with no options' do
      class NewPublisher
        include BarkMQ::Publisher
      end
      @publisher = NewPublisher.new
      expect(@publisher.model_name).to eq(nil)
    end

    it 'ActiveRecord with no options' do
      class NewArPublisher < ActiveRecord::Base
      end
      @publisher = NewArPublisher.new
      expect(@publisher.model_name).to eq('new_ar_publisher')
    end
  end

  describe '.topic' do
    it 'PORO with no options' do
      class NewPublisher
        include BarkMQ::Publisher
      end
      @publisher = NewPublisher.new
      expect(@publisher.full_topic('created')).to eq('test-barkmq-created')
    end

    it 'ActiveRecord with no options' do
      class NewArPublisher < ActiveRecord::Base
        acts_as_publisher
      end
      @publisher = NewArPublisher.new
      expect(@publisher.publish_topics[:create]).to eq('new_ar_publisher-created')
      expect(@publisher.full_topic(@publisher.publish_topics[:create])).to eq('test-barkmq-new_ar_publisher-created')
    end
  end

  describe '.publish_to_sns' do
    it 'PORO with no options' do
      class NewPublisher
        include BarkMQ::Publisher

        def serializable_hash
          { id: 1, message: 'test' }
        end
      end
      @publisher = NewPublisher.new
      expect(BarkMQ).to receive(:publish).with('test-barkmq-tested', { id: 1, message: 'test' }.to_json, { sync: true })
      @publisher.publish_to_sns('tested')
    end
  end

end
