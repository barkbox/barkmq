module BarkMQ
  module ActsAsPublisher
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def acts_as_publisher(options = {})
        send :include, InstanceMethods

        class_attribute :publish_callbacks
        class_attribute :publish_topics

        self.publish_callbacks = {}
        self.publish_topics = {}

        options[:on] ||= [ :create, :update, :destroy ]
        options[:on] = Array(options[:on])

        options[:create_topic] ||= [ self.bark_mq_model_name, 'created' ].join('-')
        options[:update_topic] ||= [ self.bark_mq_model_name, 'updated' ].join('-')
        options[:destroy_topic] ||= [ self.bark_mq_model_name, 'destroyed' ].join('-')

        self.publish_topics[:create] ||= options[:create_topic]
        self.publish_topics[:update] ||= options[:update_topic]
        self.publish_topics[:destroy] ||= options[:destroy_topic]

        options[:on].each do |action|
          BarkMQ.publisher_config do |c|
            topic = self.publish_topics[action.to_sym]
            c.add_topic(topic)
          end
          after_commit "after_#{action}_publish".to_sym, on: action.to_sym
        end
        send("message_serializer=", options[:serializer])
      end

      def add_publish_callback method, options={}
        options[:on] ||= [ :create, :update, :destroy ]
        options[:on] = Array(options[:on])
        options[:topic] # add validator

        BarkMQ.publisher_config do |c|
          c.add_topic(options[:topic])
        end

        options[:on].each do |action|
          hook = [ __callee__, 'on', action ].join('_').to_sym
          self.publish_callbacks[hook] ||= [ ]
          self.publish_callbacks[hook] << method
        end

        [ :error, :complete ].each do |callback|
          if options[callback].present?
            hook = [ __callee__, 'on', callback ].join('_').to_sym
            self.publish_callbacks[hook] ||= [ ]
            self.publish_callbacks[hook] << options[callback]
          end
        end
      end

      alias_method :after_publish, :add_publish_callback
    end

    module InstanceMethods
      def run_publish_callbacks hook, *args
        publish_callbacks[hook.to_sym].to_a.each do |method|
          if method.is_a?(Symbol) && self.respond_to?(method)
            args.present? ? self.send(method, *args) : self.send(method)
          elsif method.respond_to?(:call)
            args.present? ? method.call(*args) : method.call
          end
        end
        true
      end

      def after_create_publish
        begin
          topic = self.publish_topics[:create]
          self.publish_to_sns(topic, { sync: true })
          self.run_publish_callbacks(:after_publish_on_create)
        rescue => e
          self.run_publish_callbacks(:after_publish_on_error, e)
        ensure
          self.run_publish_callbacks(:after_publish_on_complete)
        end
      end

      def after_update_publish
        begin
          topic = self.publish_topics[:update]
          self.publish_to_sns(topic, { sync: true })
          self.run_publish_callbacks(:after_publish_on_update)
        rescue => e
          self.run_publish_callbacks(:after_publish_on_error, e)
        ensure
          self.run_publish_callbacks(:after_publish_on_complete)
        end
      end

      def after_destroy_publish
        begin
          topic = self.publish_topics[:destroy]
          self.publish_to_sns(topic, { sync: true })
          self.run_publish_callbacks(:after_publish_on_destroy)
        rescue => e
          self.run_publish_callbacks(:after_publish_on_error, e)
        ensure
          self.run_publish_callbacks(:after_publish_on_complete)
        end
      end
    end
  end
end
