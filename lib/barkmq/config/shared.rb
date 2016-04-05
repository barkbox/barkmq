module BarkMQ
  class ConfigError < StandardError; end

  module Config
    module Shared
      def self.included(base)
        base.attribute :env, String, default: 'dev'
        base.attribute :app_name, String
        base.attribute :access_key, String, default: ENV['AWS_ACCESS_KEY_ID']
        base.attribute :secret_key, String, default: ENV['AWS_SECRET_ACCESS_KEY']
        base.attribute :region, String, default: ENV['AWS_REGION'] || 'us-east-1'
        base.attribute :logger, Logger, default: Logger.new(STDERR)
        base.attribute :topic_names, Set, default: Set.new
      end

      def add_topic(model, event)
        topic_name = [env, app_name, model, event].flatten.join('-')
        topic_names.add(topic_name)
      end
    end

    def validate_setting(value, permitted_values)
      return if permitted_values.include?(value)
      raise ConfigError, "invalid value `#{value}`, must be one of #{permitted_values.inspect}"
    end

  end
end
