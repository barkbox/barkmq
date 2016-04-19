module BarkMQ
  module Handlers
    class DefaultError
      attr_reader :namespace, :logger, :statsd

      def initialize(namespace: '', logger: Logger.new(STDOUT), statsd: Statsd.new)
        self.namespace = namespace
        self.logger = logger
        self.statsd = statsd
      end

      def call topic_name, error
        logger.error "BarkMQ error. namespace=#{namespace.inspect} " +
                     "topic_name=#{topic_name.inspect} " +
                     "error=#{error.inspect}"
        statsd.increment("barkmq.message.#{namespace}.error", tags: [ "topic_name:#{topic_name}" ])
        statsd.event("BarkMQ error. namespace=#{namespace.inspect}",
                     "error=#{error.inspect}\n",
                     alert_type: 'error',
                     tags: [ "topic_name:#{topic_name}" ])
      end

      private

      attr_writer :namespace, :logger, :statsd

    end
  end
end
