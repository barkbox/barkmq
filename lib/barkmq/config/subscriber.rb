require 'virtus'
require 'barkmq/config/shared'

module BarkMQ
  module Config

    class Subscriber
      include Virtus::Model
      include Shared

      attribute :queue_name, String
      attribute :dead_letter_queue_name, String

      def queue_name
        super || "#{topic_prefix}"
      end

      def dead_letter_queue_name
        super || "#{topic_prefix}-failures"
      end

      def middleware
        @middleware ||= Circuitry::Middleware::Chain.new
        yield @middleware if block_given?
        @middleware
      end

      def handlers
        @handlers ||= {}
        @handlers
      end

      def clear_handlers
        @handlers = {}
      end

      def add_handler handler_class, options={}
        topic_name = options[:topic].to_s
        handlers[topic_name] = handler_class
      end
    end

  end
end
