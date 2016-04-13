module BarkMQ

  class MessageWorker
    include Shoryuken::Worker

    shoryuken_options queue: -> { ENV['BARKMQ_QUEUE'] || BarkMQ.sub_config.queue_name },
                      auto_delete: true

    attr_accessor :topic, :message

    server_middleware do |c|
      c.add BarkMQ::Middleware::DatadogSubscriberLogger
    end

    def perform sqs_msg, body
      BarkMQ.handle_message(topic, message)
    end

  end

end
