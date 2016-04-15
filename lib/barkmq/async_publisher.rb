require 'retries'

module BarkMQ
  class AsyncPublisher
    include Celluloid

    CONNECTION_ERRORS = [
      ::Seahorse::Client::NetworkingError,
      ::Aws::SNS::Errors::InternalFailure
    ].freeze

    def get_topic topic_name
      Shoryuken::Client.sns.create_topic(name: topic_name)
    end

    def publish(topic_name, object, options={})
      begin
        message = object.to_json
        handler = -> (e, attempt_number, _total_delay) do
          logger.warn "SNS publish error. attempt_number=#{attempt_number} " +
                       "error_class=#{e.class.inspect} " +
                       "error_message=#{e.message.inspect}"
        end
        with_retries(max_tries: 3, handler: handler, rescue: CONNECTION_ERRORS, base_sleep_seconds: 0.05, max_sleep_seconds: 0.25) do
          topic_arn = get_topic(topic_name).topic_arn
          Shoryuken::Client.sns.publish(topic_arn: topic_arn, message: message)
        end
      rescue => e
        if error_handler.present?
          error_handler.call(topic_name, e)
        else
          logger.error "Error publishing to SNS. topic_name=#{topic_name} " +
                       "error_class=#{e.class.inspect} " +
                       "error_message=#{e.message.inspect}"
          raise e
        end
      end
    end

    private

    def logger
      BarkMQ.publisher_config.logger
    end

    def error_handler
      BarkMQ.publisher_config.error_handler
    end
  end
end
