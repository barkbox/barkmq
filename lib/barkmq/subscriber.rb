module BarkMQ
  class SubscriberNotImplemented < StandardError; end

  module Subscriber
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, Shoryuken::Worker
    end

    module ClassMethods
      include Virtus::Model
      include Shoryuken::Worker

      attribute :subscriber_options, Hash

      def barkmq_subscriber_options(options = {})
        send :include, InstanceMethods

        shoryuken_options queue: BarkMQ.sub_config.queue_name,
                          auto_delete: true,
                          body_parser: JSON

        topics = Array(options[:topics])
        self.subscriber_options ||= options
        BarkMQ.subscriber_config do |c|
          topics.each do |topic|
            c.add_topic(topic)
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
