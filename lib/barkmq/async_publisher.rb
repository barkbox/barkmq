require 'retries'

module BarkMQ
  class PublishTimeout < StandardError; end

  class AsyncPublisher
    include Celluloid

    CONNECTION_ERRORS = [
      ::Seahorse::Client::NetworkingError,
      ::Aws::SNS::Errors::InternalFailure
    ].freeze

    PUBLISH_TIMEOUT = 30

    def _publish topic_name, message
      topic_arn = BarkMQ.sns_client.create_topic(name: topic_name).topic_arn
      BarkMQ.sns_client.publish(topic_arn: topic_arn, message: message)
    end

    def publish(topic_name, message, options={})
      begin
        @timer = after(options[:timeout] || PUBLISH_TIMEOUT) { timeout(topic_name) }
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
            _publish(topic_name, message)
          end
        end
      rescue => e
        error_handler.call(topic_name, e)
      ensure
        @timer.cancel if @timer
        ActiveRecord::Base.connection.close
      end
    end

    private

    def logger
      BarkMQ.publisher_config.logger
    end

    def statsd
      BarkMQ.publisher_config.statsd
    end

    def error_handler
      BarkMQ.publisher_config.error_handler
    end

    def middleware
      BarkMQ.publisher_config.middleware
    end

    def timeout topic_name
      @timer.cancel if @timer
      error_handler.call(topic_name, PublishTimeout)
    end
  end
end
