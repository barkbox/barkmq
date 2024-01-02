module BarkMQ
  module Publisher
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      attr_accessor :message_serializer

      def bark_mq_model_name
        if ancestors.include?(ActiveRecord::Base)
          model_name.param_key
        else
          nil
        end
      end
    end

    module InstanceMethods
      def bark_mq_model_name
        self.class.bark_mq_model_name
      end

      def full_topic topic
        [
          BarkMQ.pub_config.topic_namespace,
          topic
        ].flatten.compact.join('-')
      end

      def serialized_object options={}
        if self.class.message_serializer.present?
          self.class.message_serializer.new(self).to_json
        else
          self.serializable_hash.merge(options).to_json
        end
      end

      def publish_to_sns topic, options={}
        topic_name = full_topic(topic)
        message = serialized_object(options)
        options[:sync] = true if options[:sync].nil?
        BarkMQ.publish(topic_name, message, { sync: options[:sync] })
      end
    end
  end
end
