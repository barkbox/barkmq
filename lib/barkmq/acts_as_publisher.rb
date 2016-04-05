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

        BarkMQ.publisher_config do |c|
          c.add_topic(self.model_name.param_key, 'created')
          c.add_topic(self.model_name.param_key, 'updated')
          c.add_topic(self.model_name.param_key, 'destroyed')

          Array(options[:events]).each do |event|
            c.add_topic(self.model_name.param_key, event)
          end
        end

        send("message_serializer=", options[:serializer])
      end
    end

    module InstanceMethods

      def after_create_publish
        self.publish_to_sns('created')
        self.after_create_callback
      end

      def after_update_publish
        self.publish_to_sns('updated')
        self.after_update_callback
      end

      def after_destroy_publish
        self.publish_to_sns('destroyed')
        self.after_destroy_callback
      end

      def after_create_callback
        puts "after_create_callback"
      end

      def after_update_callback
        puts "after_update_callback"
      end

      def after_destroy_callback
        puts "after_destroy_callback"
      end

      def topic event
        [
          BarkMQ.pub_config.env,
          BarkMQ.pub_config.app_name,
          self.class.model_name.param_key,
          event
        ].flatten.join('-')
      end

      def publish_to_sns event='created', options={}
        topic_name = topic(event)
        if self.message_serializer.present?
          obj = self.message_serializer.new(self)
        else
          obj = self.serializable_hash.merge(options)
        end
        BarkMQ.publish(topic_name, obj, async: true, timeout: 20)
      rescue Aws::SNS::Errors::NotFound => e
        BarkMQ.pub_config.logger.error "SNS topic not found topic_name=#{topic_name.inspect}"
        $statsd.event("SNS topic not found.",
                      "topic_name=#{topic_name}\n",
                      alert_type: 'error',
                      tags: [ "category:message_queue" ])
      end

    end
  end
end
