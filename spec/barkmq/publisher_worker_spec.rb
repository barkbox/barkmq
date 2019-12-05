require 'spec_helper'

describe BarkMQ::PublisherWorker do
  describe '#perform' do
    context 'AWS returns a 404 error for topic arn' do
      it 'busts the topic arn cache and retries' do
        BarkMQ.publisher_config do |c|
          c.redis = MockRedis.new
          c.topic_arn_cache_key = 'cache'
        end
        BarkMQ.publisher_config.redis.hset('cache', 'topic', 'topic-arn')

        error = Aws::Errors::ServiceError.new(nil, '')
        allow(error).to receive(:code).and_return('404')

        worker = BarkMQ::PublisherWorker.new

        expect(worker).to receive(:perform).exactly(2).times.and_call_original
        expect(Shoryuken::Client.sns).to receive(:publish).with(topic_arn: 'topic-arn', message: 'message')
          .and_raise(error)
        expect(BarkMQ.publisher_config.topic_arn_cache).to receive(:bust).and_call_original
        expect(Shoryuken::Client.sns).to receive(:create_topic).with(name: 'topic').and_return(double('topic_arn', topic_arn: 'topic-arn'))
        expect(Shoryuken::Client.sns).to receive(:publish).with(topic_arn: 'topic-arn', message: 'message')
          .and_return(true)

        worker.perform('topic', 'message')
      end
    end
  end
end
