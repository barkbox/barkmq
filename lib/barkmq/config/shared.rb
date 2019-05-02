require 'datadog/statsd'

module BarkMQ
  Statsd = Datadog::Statsd
  class ConfigError < StandardError; end

  module Config
    module Shared
      def self.included(base)
        base.attribute :env, String, default: ENV['ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV']
        base.attribute :access_key, String, default: ENV['AWS_ACCESS_KEY_ID']
        base.attribute :secret_key, String, default: ENV['AWS_SECRET_ACCESS_KEY']
        base.attribute :region, String, default: ENV['AWS_REGION'] || 'us-east-1'
        base.attribute :logger, Logger, default: Logger.new(STDERR)
        base.attribute :topic_namespace, String, default: nil
        base.attribute :topic_names, Array, default: []
        base.attribute :statsd, Statsd, default: Statsd.new
        base.attribute :error_handler
      end

      def add_topic(topic, options={})
        full_topic = [ (options[:namespace] || topic_namespace), topic].flatten.compact.join('-')
        unless topic_names.include?(full_topic)
          topic_names << full_topic
        end
      end
    end

  end
end
