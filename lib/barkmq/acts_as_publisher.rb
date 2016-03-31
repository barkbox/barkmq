module BarkMQ
  module ActsAsPublisher
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def acts_as_publisher(options = {})
        send :include, InstanceMethods

        cattr_accessor :message_serializer

        after_commit :after_create_publish, on: :create
        after_commit :after_update_publish, on: :update
        after_commit :after_destroy_publish, on: :destroy

        Array(options[:create]).each do |callback|
          after_commit "#{callback}".to_sym, on: :create
        end
        Array(options[:update]).each do |callback|
          after_commit "#{callback}".to_sym, on: :update
        end
        Array(options[:destroy]).each do |callback|
          after_commit "#{callback}".to_sym, on: :destroy
        end

        send("message_serializer=", options[:serializer])
      end

    end

    module InstanceMethods

      def after_create_publish
        self.publish_to_sns('created')
      end

      def after_update_publish
        self.publish_to_sns('updated')
      end

      def after_destroy_publish
        self.publish_to_sns('destroyed')
      end

      def publish_to_sns event_name='created', options={}
        topic_name = "#{Rails.env}-barkbox-shipment-#{event_name}"
        if self.message_serializer.present?
          obj = self.message_serializer.new(self)
        else
          obj = self.serializable_hash.merge(options)
        end
        BarkMQ.publish(topic_name, obj, async: true, timeout: 20)
      rescue Aws::SNS::Errors::NotFound => e
        # logger.error "SNS topic not found topic_name=#{topic_name.inspect}"
        $statsd.event("SNS topic not found.",
                      "topic_name=#{topic_name}\n",
                      alert_type: 'error',
                      tags: [ "category:message_queue" ])
      end

    end
  end
end
