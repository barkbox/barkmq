module BarkMQ
  class SubscriberNotImplemented < StandardError; end

  module Subscriber
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      include Virtus::Model

      attribute :subscriber_options, Hash

      def barkmq_subscriber_options(options = {})
        send :include, InstanceMethods

        topics = Array(options[:topics])
        self.subscriber_options ||= options
        BarkMQ.subscriber_config do |c|
          topics.each do |topic|
            unless c.topic_names.include?(topic)
              c.topic_names << topic
            end
            c.add_handler self, topic: topic
          end
        end
      end
    end

    module InstanceMethods
      def perform topic, message
        raise SubscriberNotImplemented
      end
    end
  end
end
