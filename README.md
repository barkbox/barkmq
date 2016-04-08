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

`config/initializers/barkmq.rb`

```ruby
  statsd_client = Statsd.new('localhost', 8125, tags: [ "env:#{Rails.env}" ])
  topic_prefix = [ Rails.env, 'barkbox' ].join('-')

  BarkMQ.publisher_config do |c|
    c.access_key = 'ABCDEF' # Default: ENV['AWS_ACCESS_KEY_ID']
    c.secret_key = '123456' # Default: ENV['AWS_SECRET_ACCESS_KEY']
    c.region = 'us-east-1'  # Default: ENV['AWS_REGION'] or 'us-east-1'

    c.logger = Rails.logger # Default: Logger.new(STDERR)
    c.topic_prefix = topic_prefix # Default: 'dev-unknown'
    c.statsd = statsd_client # Default: Statsd.new

    # Optional but recommended.
    c.error_handler = BarkMQ::Handlers::DefaultError.new namespace: 'publisher',
                                                         logger: Rails.logger,
                                                         statsd: statsd_client

    c.middleware.add BarkMQ::Middleware::DatadogLogger, namespace: 'publisher',
                                                        logger: Rails.logger,
                                                        statsd: statsd_client
  end

  BarkMQ.subscriber_config do |c|
    c.access_key = 'ABCDEF' # Default: ENV['AWS_ACCESS_KEY_ID']
    c.secret_key = '123456' # Default: ENV['AWS_SECRET_ACCESS_KEY']
    c.region = 'us-east-1'  # Default: ENV['AWS_REGION'] or 'us-east-1'

    c.logger = Rails.logger # Default: Logger.new(STDERR)
    c.topic_prefix = topic_prefix # Default: 'dev-unknown'
    c.statsd = statsd_client # Default: Statsd.new

    # Optional but recommended.
    c.error_handler = BarkMQ::Handlers::DefaultError.new namespace: 'subscriber',
                                                         logger: Rails.logger,
                                                         statsd: statsd_client

    c.middleware.add BarkMQ::Middleware::DatadogLogger, namespace: 'subscriber',
                                                        logger: Rails.logger,
                                                        statsd: statsd_client
  end
```

## Usage

### Publisher

Add `acts_as_publisher` to any ActiveRecord model to enable publisher capabilities.

By default the create, update, and destroy events are enabled.

You can specify a custom serializer by passing a ActiveSerializer object as a `serializer` argument.

A custom method can be executed after a successful publishing of a `created`, `update`, and `destroy` event by using the `after_publish` method. The options are `event` and `on` as shown below.

```ruby
class User < ActiveRecord::Base
  acts_as_publisher on: [ :create, :update ], # Optional. Default: [ :create, :update, :destroy]
                    serializer: Api::V2::Internal::UserSerializer # Optional. Default: to_json method

  after_publish :publish_registered, event: 'registered', # Optional. Default is method name stringify'ed
                                     on: [ :create ] # Optional. Default: [ :create, :update, :destroy ]
  after_publish :publish_registered, event: 'email_changed', # Optional. Default is method name stringify'ed
                                     on: [ :create, :update ] # Optional. Default: [ :create, :update, :destroy ]

  def publish_registered
    self.publish_to_sns('registered')
  end

  def publish_email_changed
    if self.email.present? && self.previous_changes.key?(:email)
      self.publish_to_sns('email_changed')
    end
  end
end
```

### Subscriber

To create a worker that listens to a specific SNS topic include `BarkMQ::Subscriber` and call the `barkmq_subscriber_options` method.

The `perform` method must be implemented as show below or an exception will be triggered.

The execution is synchronous so if it's time intensive pass it off to a delayed worker. By default the execution timeout is 30 seconds.

```ruby
class UserRegisteredWorker
  include BarkMQ::Subscriber

  barkmq_subscriber_options topics: [ "#{Rails.env}-barkbox-user-registered" ]

  def perform topic, message
    user_id = message['user']['id']
    UserMailer.delay(queue: 'user_welcome_email').welcome_email(user_id)
  end
end
```

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
