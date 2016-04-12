# Configuration

## Shared

Both Publisher and Subscription configurations shared the following options.

### env
String. Optional. Default: `ENV['ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV']`

Environment.

### access_key
String. Optional. Default: `ENV['AWS_ACCESS_KEY_ID']`

AWS Access Key with SQS and SNS rights.

### secret_key
String. Optional. Default: `ENV['AWS_SECRET_ACCESS_KEY']`

AWS Secret Access Key.

### region
String. Optional. Default: `ENV['AWS_REGION'] || 'us-east-1'`

AWS region.

### logger
Logger. Optional. Default: `Logger.new(STDERR)`

Logger object.

### topic_namespace
String. Optional. Default: `nil`

Topic namespace, all topics will have this pre-prended, separated by a hyphen. i.e. If the a given topic namespace is `dev-barkbox` and a topic is `user_registered` then the full topic will be `dev-barkbox-user_registered`.

### topic_names
Array. Optional. Default: `[]`

List of topics currently configured.

### statsd
Statsd. Optional. Default: `Statsd.new`

Statsd object for instrumentation.

### error_handler
Object that responds to call. Optional. Default: `nil`

Called if internals of a subscriber or publisher throws an exception.

## Publisher

### middleware

## Subscriber

### queue_name
String. Required.

The name of the SQS queue that will be subscribed to relevant SNS topics.

### dead_letter_queue_name
String. Optional. Default: `#{queue_name}-failures`

When a subscriber fails to complete a task in a queue n times it will be moved to this queue for manual inspection.
