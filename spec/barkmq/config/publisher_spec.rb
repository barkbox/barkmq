require 'spec_helper'

describe BarkMQ::Config::Publisher do
  it 'requires a redis connection be provided' do
    config = BarkMQ::Config::Publisher.new
    config.redis = MockRedis.new


    expect(config.redis).to be_present
    expect(config.topic_arn_cache_key).to eq('barkmq_topic_arn_cache')
  end

  it 'allows an explict cache key to be set' do
    config = BarkMQ::Config::Publisher.new
    config.redis = MockRedis.new
    config.topic_arn_cache_key = 'my_cache_key'

    expect(config.redis).to be_present
    expect(config.topic_arn_cache_key).to eq('my_cache_key')
  end

  describe '#topic_arn_cache' do
    it 'raises an error if no redis connection was provided' do
      config = BarkMQ::Config::Publisher.new

      expect{config.topic_arn_cache}.to raise_error('You must provide a Redis connection to the publisher config')
    end

    it 'returns an instance of BarkMQ::Cache' do
      config = BarkMQ::Config::Publisher.new
      config.redis = MockRedis.new

      expect(config.topic_arn_cache).to be_a(BarkMQ::Cache)
    end
  end

  describe '#get_topic_arn' do
    it 'passes the request to the topic_arn_cache' do
      config = BarkMQ::Config::Publisher.new
      config.redis = MockRedis.new

      expect(config.topic_arn_cache).to receive(:get).with('my_key').and_return('my_key')
      config.get_topic_arn('my_key')
    end
  end
end
