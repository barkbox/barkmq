module BarkMQ
  module Subscriber
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Virtus::Model

      attribute :subscriber_options, Hash

      def barkmq_subscriber_options(options = {})
        topics = Array(options[:topics])
        self.subscriber_options ||= options
        BarkMQ.subscriber_config do |c|
          topics.each do |topic|
            c.topic_names.add(topic)
            c.add_handler ShipmentShippedWorker, topic: topic
          end
        end
      end

    end

    module InstanceMethods

    end
  end
end
