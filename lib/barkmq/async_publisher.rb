class AsyncPublisher
  include Celluloid

  def publish(topic, object, options={})
    Circuitry::Publisher.new(options).publish(topic, object)
    Circuitry.flush
  end
end
