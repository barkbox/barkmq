module BarkMQ
  module Middleware
    class DatadogSubscriberLogger

      def call(worker_instance, queue, sqs_msg, body)
        start_time = Time.now
        message = Circuitry::Message.new(sqs_msg)
        topic = message.topic.name
        worker_instance.topic = topic
        worker_instance.message = message.body
        logger.info "metric=#{start_metric.inspect} " +
                    "topic=#{worker_instance.topic.inspect} " +
                    "start_time=#{start_time.inspect}"
        statsd.increment(start_metric, tags: [ "topic:#{topic}" ])
        yield
      ensure
        end_time = Time.now
        response_time = ((end_time - start_time) * 1000).to_i
        logger.info "metric=#{end_metric.inspect} " +
                    "topic=#{worker_instance.topic.inspect} " +
                    "response_time=#{response_time.inspect}ms"
        statsd.increment(end_metric, tags: [ "topic:#{topic}" ])
        statsd.gauge(time_metric, response_time, tags: [ "topic:#{topic}" ])
      end

      def logger
        BarkMQ.sub_config.logger
      end

      def statsd
        BarkMQ.sub_config.statsd
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

    end
  end
end
