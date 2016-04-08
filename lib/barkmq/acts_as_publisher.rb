module BarkMQ
  module ActsAsPublisher
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def acts_as_publisher(options = {})
        send :include, InstanceMethods

        class_attribute :publish_callbacks

        self.publish_callbacks = {}

        options[:on] ||= [ :create, :update, :destroy ]
        options[:on] = Array(options[:on])
        event_lookup = {
          create: 'created',
          update: 'updated',
          destroy: 'destroyed'
        }

        options[:on].each do |action|
          BarkMQ.publisher_config do |c|
            c.add_topic(self.model_name.param_key, event_lookup[action])
          end
          after_commit "after_#{action}_publish".to_sym, on: action.to_sym
        end
        send("message_serializer=", options[:serializer])
      end

      def add_publish_callback method, options={}
        options[:on] ||= [ :create, :update, :destroy ]
        options[:on] = Array(options[:on])
        options[:event] ||= method.to_s

        BarkMQ.publisher_config do |c|
          c.add_topic(self.model_name.param_key, options[:event])
        end

        options[:on].each do |action|
          hook = [ __callee__, 'on', action ].join('_').to_sym
          self.publish_callbacks[hook] ||= [ ]
          self.publish_callbacks[hook] << [ method, options ]
        end
      end

      alias_method :after_publish, :add_publish_callback
    end

    module InstanceMethods
      def run_publish_callbacks hook
        publish_callbacks[hook.to_sym].to_a.each do |callback|
          method = callback[0]
          options = callback[1]
          if method.is_a?(Symbol) && self.respond_to?(method)
            self.send(method)
          elsif self.respond_to?(:call)
            method.call
          end
        end
        true
      end

      def after_create_publish
        self.publish_to_sns('created')
        self.run_publish_callbacks(:after_publish_on_create)
      end

      def after_update_publish
        self.publish_to_sns('updated')
        self.run_publish_callbacks(:after_publish_on_update)
      end

      def after_destroy_publish
        self.publish_to_sns('destroyed')
        self.run_publish_callbacks(:after_publish_on_destroy)
      end
    end
  end
end
