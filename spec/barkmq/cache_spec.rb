require 'spec_helper'

describe 'BarkMQ::Cache' do
  describe 'initialize' do
    it 'takes a redis connection and a cache key' do
      redis = double('redis')
      cache_key = 'some_key'

      cache = BarkMQ::Cache.new(redis, cache_key)
      expect(cache.conn).to eq(redis)
      expect(cache.cache_key).to eq(cache_key)
    end
  end

  describe '#get(key)' do
    context 'key exists in cache' do
      it 'returns the arn associated with the key' do
        redis = MockRedis.new
        cache_key = 'barkmq_topic_arn_cache'
        topic_key = 'some_topic'
        topic_arn = 'some_topic-arn'
        redis.hset(cache_key, topic_key, topic_arn)

        cache = BarkMQ::Cache.new(redis, cache_key)

        expect(cache.get(topic_key)).to eq(topic_arn)
      end
    end

    context 'key does not exist in cache' do
      context 'key is successfully created on SNS' do
        it 'returns the key and adds it to the cache' do
          redis = MockRedis.new
          cache_key = 'barkmq_topic_arn_cache'
          topic_key = 'some_topic'
          topic_arn = 'some_topic-arn'

          cache = BarkMQ::Cache.new(redis, cache_key)

          topic_response = double('topic_response', topic_arn: topic_arn)
          expect(Shoryuken::Client.sns).to receive(:create_topic).with(name: topic_key).and_return(topic_response)

          expect(cache.get(topic_key)).to eq(topic_response.topic_arn)
          expect(redis.hget(cache_key, topic_key)).to eq(topic_arn)
        end
      end

      context 'an error occurs creating the key on SNS' do
        it 'raises the error and busts the cache' do
          redis = MockRedis.new
          cache_key = 'barkmq_topic_arn_cache'
          topic_key = 'some_topic'

          cache = BarkMQ::Cache.new(redis, cache_key)

          topic_response = double('topic_response', arn: topic_key)
          expect(Shoryuken::Client.sns).to receive(:create_topic).with(name: topic_key).and_raise('ERROR')

          expect{ cache.get(topic_key) }.to raise_error('ERROR')
          expect(redis.exists(cache_key)).to eq(false)
        end
      end
    end
  end

  describe '#bust' do
    context 'the cache key exists' do
      it 'deletes the cache key and returns 1' do
          redis = MockRedis.new
          cache_key = 'barkmq_topic_arn_cache'
          redis.hset(cache_key, 'some_key', 'some_arn')

          cache = BarkMQ::Cache.new(redis, cache_key)
          expect(cache.bust).to eq(1)
          expect(redis.exists(cache_key)).to eq(false)
      end
    end

    context 'the cache key does not exist' do
      it 'returns 0' do
          redis = MockRedis.new
          cache_key = 'barkmq_topic_arn_cache'

          cache = BarkMQ::Cache.new(redis, cache_key)
          expect(cache.bust).to eq(0)
      end
    end
  end
end
