module BarkMQ
  class Cache
    attr_reader :conn, :cache_key

    def initialize(redis, cache_key)
      @conn = redis
      @cache_key = cache_key
    end

    def get(key)
      arn = conn.hget(cache_key, key)
      if !arn
        begin
          arn = Shoryuken::Client.sns.create_topic(name: key).topic_arn
          conn.hset(cache_key, key, arn)
        rescue StandardError => e
          bust
          raise e
        end
      end
      arn
    end

    def bust
      conn.del(cache_key)
    end
  end
end
