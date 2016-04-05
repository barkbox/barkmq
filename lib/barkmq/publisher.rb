module BarkMQ
  module Publisher
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
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
          BarkMQ.pub_config.env,
          BarkMQ.pub_config.app_name,
          self.model_name,
          event
        ].flatten.compact.join('-')
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
