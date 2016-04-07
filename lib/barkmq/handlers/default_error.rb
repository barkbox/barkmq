module BarkMQ
  module Handlers
    class DefaultError
      attr_reader :namespace, :logger, :statsd

      def initialize(namespace: '', logger: Logger.new(STDOUT), statsd: Statsd.new)
        self.namespace = namespace
        self.logger = logger
        self.statsd = statsd
      end

      def call error
        logger.error "BarkMQ #{namespace} error=#{error.inspect}"
        statsd.increment("barkmq.message.#{namespace}.error", tags: [ "category:#{namespace}" ])
        statsd.event("BarkMQ #{namespace} error.",
                     "error=#{error.inspect}\n",
                     alert_type: 'error',
                     tags: [ "category:#{namespace}" ])
        Circuitry.flush if namespace == 'publisher'
      end

      private
      attr_writer :namespace, :logger, :statsd

    end
  end
end
