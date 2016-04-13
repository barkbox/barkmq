module BarkMQ
  module Middleware
    class DatadogSubscriberLogger

      def call(worker_instance, queue, sqs_msg, body)
        start_time = Time.now
        # logger.info("metric=#{start_metric.inspect} topic=#{topic.inspect} start_time=#{start_time.inspect}")
        logger.info("metric=#{start_metric.inspect} start_time=#{start_time.inspect}")
        # unless start_metric.blank?
        #   statsd.increment(start_metric, tags: [ "topic:#{topic}" ])
        # end
        yield
        end_time = Time.now
        response_time = ((end_time - start_time) * 1000).to_i
        # logger.info("metric=#{end_metric.inspect} topic=#{topic.inspect} response_time=#{response_time.inspect}ms")
        logger.info("metric=#{end_metric.inspect} response_time=#{response_time.inspect}ms")
      end

      def logger
        BarkMQ.sub_config.logger
      end

      def start_metric
        'barkmq.message.received'
      end

      def end_metric
        'barkmq.message.processed'
      end

      def time_metric
        'barkmq.message.process.time'
      end

      # def call(topic, message)
      #   start_time = Time.now
      #   logger.info("metric=#{start_metric.inspect} topic=#{topic.inspect} start_time=#{start_time.inspect}")
      #   unless start_metric.blank?
      #     statsd.increment(start_metric, tags: [ "topic:#{topic}" ])
      #   end
      #   yield
      # ensure
      #   end_time = Time.now
      #   response_time = ((end_time - start_time) * 1000).to_i
      #   logger.info("metric=#{end_metric.inspect} topic=#{topic.inspect} response_time=#{response_time.inspect}ms")
      #   unless end_metric.blank?
      #     statsd.increment(end_metric, tags: [ "topic:#{topic}" ])
      #     statsd.gauge(time_metric, response_time, tags: [ "topic:#{topic}" ])
      #   end
      # end
    end
  end
end
