require 'circuitry'
require 'shoryuken'
require 'celluloid'
require 'sidekiq'
require 'celluloid/current'
require 'barkmq/railtie' if defined?(Rails) && Rails::VERSION::MAJOR >= 3
require 'barkmq/config/subscriber'
require 'barkmq/config/publisher'
require 'barkmq/handlers/default_error'
require 'barkmq/middleware/datadog_publisher_logger'
require 'barkmq/middleware/datadog_subscriber_logger'
require 'barkmq/subscriber'
require 'barkmq/publisher'
require 'barkmq/acts_as_publisher'
require 'barkmq/async_publisher'
require 'barkmq/publisher_worker'
require 'barkmq/frameworks/active_record' if defined?(ActiveRecord)
require 'barkmq/version'

module BarkMQ
  class HandlerNotFound < StandardError; end

  class << self

    def subscriber_config(&block)
      @_sub_config ||= Config::Subscriber.new
      yield @_sub_config if block_given?
      Circuitry.subscriber_config do |c|
        c.queue_name = @_sub_config.queue_name
        c.topic_names = @_sub_config.topic_names
        c.visibility_timeout = 30
      end
      require 'barkmq/message_worker'
      @_sub_config
    end

    def sub_config
      @_sub_config ||= Config::Subscriber.new
      @_sub_config
    end

    def publisher_config(&block)
      @_pub_config ||= Config::Publisher.new
      yield @_pub_config if block_given?
      @_pub_config.middleware ||= BarkMQ::Middleware::DatadogPublisherLogger.new logger: @_pub_config.logger,
                                                                                 statsd: @_pub_config.statsd
      @_pub_config.error_handler ||= BarkMQ::Handlers::DefaultError.new namespace: 'publisher',
                                                                        logger: @_pub_config.logger,
                                                                        statsd: @_pub_config.statsd
      Circuitry.publisher_config do |c|
        c.access_key = @_pub_config.access_key
        c.secret_key = @_pub_config.secret_key
        c.region = @_pub_config.region
        c.logger = @_pub_config.logger

        c.async_strategy = :batch
        c.topic_names = @_pub_config.topic_names
      end

      concurrency = ENV['BARKMQ_PUBLISHER_CONCURRENCY'] || Celluloid.cores
      Celluloid::Actor[:publisher] ||= BarkMQ::AsyncPublisher.pool(size: concurrency)
      @_pub_config
    end

    def pub_config
      @_pub_config ||= Config::Publisher.new
      @_pub_config
    end

    def handle_message topic_name, message
      if @_sub_config.handlers[topic_name.to_s]
        @_sub_config.handlers[topic_name.to_s].new.perform(topic_name, message)
      else
        raise HandlerNotFound
      end
    end

    def publish(topic_name, object, options={})
      if options[:sync] == true
        BarkMQ::PublisherWorker.perform_async(topic_name, object, options)
      else
        Celluloid::Actor[:publisher].async.publish(topic_name, object, options)
      end
    end

    def sns_client
      @sns_client ||= Aws::SNS::Client.new
    end

  end
end
