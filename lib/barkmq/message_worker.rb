require 'barkmq/config/subscriber'

module BarkMQ

  class MessageWorker
    include Shoryuken::Worker

    shoryuken_options queue: -> { ENV['BARKMQ_QUEUE'] || BarkMQ.sub_config.queue_name },
                      auto_delete: true

    def perform sqs_msg, body
      message = Circuitry::Message.new(sqs_msg)
      topic_name = message.topic.name
      BarkMQ.handle_message(topic_name, message.body)
    end

  end

end
