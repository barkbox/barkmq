# Subscriber
To create a subscriber just add `include BarkMQ::Subscriber` to a class.

```ruby
class ShipmentShippedWorker
  include BarkMQ::Subscriber

  barkmq_subscriber_options topics: [ "shipment-shipped" ]

  def perform topic, message
    # Work here
  end

end
```

## barkmq_subscriber_options

### topics
Name of the topics that the worker should be listening for.

## perform
Add the `perform` method that takes an SNS topic and message as arguments to implement your worker.
