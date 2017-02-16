require 'virtus'
require 'barkmq/config/shared'

module BarkMQ
  module Config

    class Subscriber
      include Virtus::Model
      include Shared

      attribute :queue_name, String
      attribute :dead_letter_queue_name, String

      def dead_letter_queue_name
        super || "#{queue_name}-failures"
      end

      def handlers
        @handlers ||= {}
        @handlers
      end

      def clear_handlers
        @handlers = {}
      end

      def add_handler handler_class, options={}
        topic_name = [ (options[:namespace] || self.topic_namespace), options[:topic].to_s ].compact.join('-')
        BarkMQ.sub_config.logger.info "add_handler: handler_class=#{handler_class.inspect} topic_name=#{topic_name.inspect}"
        handlers[topic_name] = handler_class
      end
    end

  end
end
