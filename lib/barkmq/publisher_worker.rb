require 'retries'

module BarkMQ

  class PublisherWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'barkmq_publisher',
                    retry: 3

    CONNECTION_ERRORS = [
      ::Seahorse::Client::NetworkingError,
      ::Aws::SNS::Errors::InternalFailure
    ].freeze

    def perform(topic_name, message, options={})
      begin
        handler = -> (e, attempt_number, _total_delay) do
          logger.error "SNS publish error. " +
                       "attempt_number=#{attempt_number} " +
                       "error_class=#{e.class.inspect} " +
                       "error_message=#{e.message.inspect}"
        end
        middleware.call(topic_name, message) do
          with_retries(max_tries: 3, handler: handler,
                                     rescue: CONNECTION_ERRORS,
                                     base_sleep_seconds: 0.05,
                                     max_sleep_seconds: 0.25) do
            BarkMQ::Publisher.publish(topic_name, message)
          end
        end
      rescue ::Aws::Errors::ServiceError => e
        if e.code == '404'
          BarkMQ.publisher_config.topic_arn_cache.bust
          perform(topic_name, message, options)
        else
          error_handler.call(topic_name, e)
        end
      rescue StandardError => e
        error_handler.call(topic_name, e)
      ensure
        ActiveRecord::Base.connection.close
      end
    end

    private

    def publisher
      BarkMQ::Publisher
    end

    def logger
      BarkMQ.publisher_config.logger
    end

    def statsd
      BarkMQ.publisher_config.statsd
    end

    def topic_arn_cache
      BarkMQ.publisher_config.topic_arn_cache
    end

    def error_handler
      BarkMQ.publisher_config.error_handler
    end

    def middleware
      BarkMQ.publisher_config.middleware
    end

  end
end
