require 'circuitry'
require 'barkmq/railtie' if defined?(Rails) && Rails::VERSION::MAJOR >= 3
require 'barkmq/config/subscriber'
require 'barkmq/config/publisher'
require 'barkmq/middleware/datadog_logger'
require 'barkmq/subscriber'
require 'barkmq/publisher'
require 'barkmq/acts_as_publisher'
require 'barkmq/frameworks/active_record' if defined?(ActiveRecord)
require 'barkmq/version'

module BarkMQ
  class HandlerNotFound < StandardError; end

  class << self

    def subscriber_config(&block)
      @_sub_config ||= Config::Subscriber.new
      yield @_sub_config if block_given?
      logger = @_sub_config.logger
      statsd = @_sub_config.statsd
      Circuitry.subscriber_config do |c|
        c.queue_name = @_sub_config.queue_name
        c.dead_letter_queue_name = @_sub_config.dead_letter_queue_name
        c.topic_names = @_sub_config.topic_names
        c.max_receive_count = 8
        c.visibility_timeout = 30
        c.access_key = @_sub_config.access_key
        c.secret_key = @_sub_config.secret_key
        c.region = @_sub_config.region
        c.logger = @_sub_config.logger
        c.error_handler = proc do |error|
          logger.error "BarkMQ subscriber error=#{error.inspect}"
          statsd.increment("message.subscriber.error", tags: [ ])
          statsd.event("BarkMQ subscriber error.",
                       "error=#{error.inspect}\n",
                       alert_type: 'error',
                       tags: [ "category:message_queue" ])
        end
        c.lock_strategy = Circuitry::Locks::Redis.new(client: Redis.new)
        c.async_strategy = :thread
        c.on_async_exit = proc do
          if defined?(ActiveRecord::Base)
            ActiveRecord::Base.connection.close
          end
        end
        c.middleware.clear
        @_sub_config.middleware.entries.each do |entry|
          c.middleware.add(entry.klass, *entry.args)
        end
      end
      @_sub_config
    end

    def sub_config
      @_sub_config ||= Config::Subscriber.new
      @_sub_config
    end

    def publisher_config(&block)
      @_pub_config ||= Config::Publisher.new
      yield @_pub_config if block_given?
      logger = @_pub_config.logger
      statsd = @_pub_config.statsd
      Circuitry.publisher_config do |c|
        c.access_key = @_pub_config.access_key
        c.secret_key = @_pub_config.secret_key
        c.region = @_pub_config.region
        c.logger = @_pub_config.logger

        c.async_strategy = :thread
        c.topic_names = @_pub_config.topic_names

        c.error_handler = proc do |error|
          logger.error "BarkMQ publisher error=#{error.inspect}"
          statsd.increment("message.publisher.error", tags: [ ])
          statsd.event("BarkMQ publisher error.",
                       "error=#{error.inspect}\n",
                       alert_type: 'error',
                       tags: [ "category:message_queue" ])
          Circuitry.flush
        end

        @_pub_config.middleware.entries.each do |entry|
          c.middleware.add(entry.klass, *entry.args)
        end
      end
      @_pub_config
    end

    def pub_config
      @_pub_config ||= Config::Publisher.new
      @_pub_config
    end

    def subscribe!(options={})
      Circuitry.subscribe(options) do |message, topic_name|
        BarkMQ.handle_message(topic_name, message, options)
      end
    end

    def handle_message topic_name, message
      if @_sub_config.handlers[topic_name.to_s]
        @_sub_config.handlers[topic_name.to_s].new.perform(topic_name, message)
      else
        raise HandlerNotFound
      end
    end

    def publish(topic_name, object, options={})
      Circuitry::Publisher.new(options).publish(topic_name, object)
    end

  end
end
