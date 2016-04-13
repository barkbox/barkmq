require 'circuitry'
require 'shoryuken'
require 'barkmq/railtie' if defined?(Rails) && Rails::VERSION::MAJOR >= 3
require 'barkmq/config/subscriber'
require 'barkmq/config/publisher'
require 'barkmq/handlers/default_error'
require 'barkmq/middleware/datadog_logger'
require 'barkmq/middleware/datadog_subscriber_logger'
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
      require 'barkmq/message_worker'
      BarkMQ::MessageWorker.server_middleware do |c|
        # BarkMQ.sub_config.middleware.entries.each do
          c.add BarkMQ::Middleware::DatadogSubscriberLogger
        # end
        # @_sub_config.middleware.entries.each do |entry|
        #   c.middleware.add(entry.klass, *entry.args)
        # end
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
      Circuitry.publisher_config do |c|
        c.access_key = @_pub_config.access_key
        c.secret_key = @_pub_config.secret_key
        c.region = @_pub_config.region
        c.logger = @_pub_config.logger

        c.async_strategy = :thread
        c.on_async_exit = proc do
          # Circuitry.flush
        end
        c.topic_names = @_pub_config.topic_names
        c.error_handler = @_pub_config.error_handler

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
        BarkMQ.handle_message(topic_name, message)
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
