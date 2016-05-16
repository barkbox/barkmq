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

## namespace
There is an optional namespace option to override the default topic namespace configured in the intiializer.

## perform
Add the `perform` method that takes an SNS topic and message as arguments to implement your worker.
