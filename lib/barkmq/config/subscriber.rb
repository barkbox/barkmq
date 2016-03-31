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
        super || "#{Rails.env}-#{app_name}"
      end

      def dead_letter_queue_name
        super || "#{Rails.env}-#{app_name}-failures"
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

      def add_handler handler_class, options={}
        topic_name = options[:topic].to_sym
        handlers[topic_name] = handler_class
      end
    end

  end
end
