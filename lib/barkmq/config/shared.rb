require 'statsd'

module BarkMQ
  class ConfigError < StandardError; end

  module Config
    module Shared
      def self.included(base)
        base.attribute :env, String, default: ENV['ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV']
        base.attribute :access_key, String, default: ENV['AWS_ACCESS_KEY_ID']
        base.attribute :secret_key, String, default: ENV['AWS_SECRET_ACCESS_KEY']
        base.attribute :region, String, default: ENV['AWS_REGION'] || 'us-east-1'
        base.attribute :logger, Logger, default: Logger.new(STDERR)
        base.attribute :topic_prefix, String, default: 'dev-unknown'
        base.attribute :topic_names, Array, default: []
        base.attribute :statsd, Statsd, default: Statsd.new
        base.attribute :error_handler
      end

      def add_topic(model, event)
        topic_name = [topic_prefix, model, event].flatten.compact.join('-')
        unless topic_names.include?(topic_name)
          topic_names << topic_name
        end
      end
    end

    def validate_setting(value, permitted_values)
      return if permitted_values.include?(value)
      raise ConfigError, "invalid value `#{value}`, must be one of #{permitted_values.inspect}"
    end

  end
end
