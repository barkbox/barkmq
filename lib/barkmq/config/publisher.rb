require 'virtus'
require 'barkmq/config/shared'

module BarkMQ
  module Config

    class Publisher
      include Virtus::Model
      include Shared

      attribute :middleware
      attribute :redis
      attribute :topic_arn_cache_key, String, default: 'barkmq_topic_arn_cache'

      def topic_arn_cache
        raise 'You must provide a Redis connection to the publisher config' unless redis
        @topic_arn_cache ||= BarkMQ::Cache.new(redis, topic_arn_cache_key)
      end

      def get_topic_arn(topic_name)
        topic_arn_cache.get(topic_name)
      end
    end
  end
end
