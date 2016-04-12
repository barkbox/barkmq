module BarkMQ
  module Publisher
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      attr_accessor :message_serializer
    end

    module InstanceMethods

      def model_name
        if self.class.ancestors.include?(ActiveRecord::Base)
          self.class.model_name.param_key
        else
          nil
        end
      end

      def topic event
        [
          BarkMQ.pub_config.topic_namespace,
          self.model_name,
          event
        ].flatten.compact.join('-')
      end

      def serialized_object options={}
        if self.class.message_serializer.present?
          self.class.message_serializer.new(self)
        else
          self.serializable_hash.merge(options)
        end
      end

      def publish_to_sns event='created', options={}
        topic_name = topic(event)
        obj = serialized_object(options)
        BarkMQ.publish(topic_name, obj, async: true, timeout: 20)
      rescue Aws::SNS::Errors::NotFound => e
        BarkMQ.pub_config.logger.error "SNS topic not found topic_name=#{topic_name.inspect}"
        BarkMQ.pub_config.statsd.event("SNS topic not found.",
                                       "topic_name=#{topic_name}\n",
                                       alert_type: 'error',
                                       tags: [ "category:message_queue" ])
      end

    end
  end
end
