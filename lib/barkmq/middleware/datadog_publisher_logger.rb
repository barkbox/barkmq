module BarkMQ
  module Middleware
    class DatadogPublisherLogger
      attr_reader :logger, :statsd

      def initialize(logger: Logger.new(STDOUT), statsd: Statsd.new)
        self.logger = logger
        self.statsd = statsd
      end

      def call(topic, message)
        start_time = Time.now
        logger.info("metric=#{start_metric.inspect} topic=#{topic.inspect} start_time=#{start_time.inspect}")
        unless start_metric.blank?
          statsd.increment(start_metric, tags: [ "topic:#{topic}" ])
        end
        yield
      ensure
        end_time = Time.now
        response_time = ((end_time - start_time) * 1000).to_i
        logger.info("metric=#{end_metric.inspect} topic=#{topic.inspect} response_time=#{response_time.inspect}ms")
        unless end_metric.blank?
          statsd.increment(end_metric, tags: [ "topic:#{topic}" ])
          statsd.gauge(time_metric, response_time, tags: [ "topic:#{topic}" ])
        end
      end

      def start_metric
        'barkmq.message.publish'
      end

      def end_metric
        'barkmq.message.published'
      end

      def time_metric
        'barkmq.message.publish.time'
      end

      private

      attr_writer :logger, :statsd
    end
  end
end
