module BarkMQ
  module Middleware
    class DatadogLogger
      attr_reader :namespace, :logger

      def initialize(namespace: '', logger: Logger.new(STDOUT))
        self.namespace = namespace
        self.logger = logger
      end

      def call(topic, message)
        start_time = Time.now
        logger.info("metric=#{start_metric.inspect} topic=#{topic.inspect} start_time=#{start_time.inspect}")
        unless start_metric.blank?
          $statsd.increment(start_metric, tags: [ "topic:#{topic}" ])
        end
        yield
      ensure
        end_time = Time.now
        response_time = ((end_time - start_time) * 1000).to_i
        logger.info("metric=#{end_metric.inspect} topic=#{topic.inspect} response_time=#{response_time.inspect}ms")
        unless end_metric.blank?
          $statsd.increment(end_metric, tags: [ "topic:#{topic}" ])
          $statsd.gauge(time_metric, response_time, tags: [ "topic:#{topic}" ])
        end
      end

      def start_metric
        case namespace
        when 'publisher'
          'message.publish'
        when 'subscriber'
          'message.received'
        else
          nil
        end
      end

      def end_metric
        case namespace
        when 'publisher'
          'message.published'
        when 'subscriber'
          'message.processed'
        else
          nil
        end
      end

      def time_metric
        case namespace
        when 'publisher'
          'message.publish.time'
        when 'subscriber'
          'message.process.time'
        else
          nil
        end
      end

      private

      attr_writer :namespace, :logger
    end
  end
end
