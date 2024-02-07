# BarkMQ

A Pub/Sub gem with an opinionated set of defaults for BarkCo projects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'barkmq'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install barkmq


## Configuration

Configured BarkMQ in an initializer such as `config/initializers/barkmq.rb`

```ruby
topic_namespace = [ Rails.env, 'barkbox' ].join('-')
queue_name = [ Rails.env, 'barkbox' ].join('-')
statsd_client = Statsd.new('localhost', 8125, tags: [ "env:#{Rails.env}" ])

BarkMQ.publisher_config do |c|
  c.logger = Rails.logger
  c.topic_namespace = topic_namespace
  c.statsd = statsd_client

  c.error_handler = BarkMQ::Handlers::DefaultError.new namespace: 'publisher',
                                                       logger: Rails.logger,
                                                       statsd: statsd_client
end

BarkMQ.subscriber_config do |c|
  c.logger = Rails.logger
  c.topic_namespace = topic_namespace
  c.statsd = statsd_client
  c.queue_name = queue_name
end

```
[Full Configuration Details](docs/config.md)

## Usage

### Publisher

Call `acts_as_publisher` to any ActiveRecord model to enable publisher functionality. This will add the `publish_to_sns` convenience method that will serialize the ActiveRecord model and publish to the appropriate SNS topic.

```ruby
class User < ActiveRecord::Base
  acts_as_publisher on: [ :create, :update ],
                    serializer: UserSerializer

  after_publish :publish_registered, topic: 'user-registered',
                                     on: [ :create ],
                                     error: publish_registered_error,
                                     complete: Proc.new { puts "complete: " }

  def publish_registered
    self.publish_to_sns('user-registered')
  end

  def publish_registered_error error
    Rails.logger.error "Publish user registered failed. error=#{error.inspect}"
  end
end
```

Ensure that sidekiq is running for publishing.

Make sure to include in your sidekiq queue the following queue *barkmq_publisher*

[Full Publisher Details](docs/publisher.md)

### Subscriber

To create a worker that listens to a specific SNS topic include `BarkMQ::Subscriber` and call the `barkmq_subscriber_options` method.

The `perform` method must be implemented as show below or an exception will be triggered.

The execution is synchronous so if it's time intensive pass it off to a delayed worker. By default the execution timeout is 30 seconds.

```ruby
class UserRegisteredWorker
  include BarkMQ::Subscriber

  barkmq_subscriber_options topics: [ "user-registered" ]

  def perform topic, message
    user_id = message['user']['id']
    UserMailer.delay(queue: 'user_welcome_email').welcome_email(user_id)
  end
end
```
[Full Subscriber Details](docs/subscriber.md)

### Setup
To create the AWS SNS topics, SQS queues, and the appropriate subscription relationships:

    $ rake barkmq:setup

### Deployment
To process jobs in the SQS queue:

    $ rake barkmq:work

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/barkbox/barkmq.

## Publishing new gem version
* bump version
* commit to master
* `gem_push=no rake release`
