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
config/initializers/barkmq.rb
```ruby
  statsd_client = Statsd.new('localhost', 8125, namespace: 'barkbox',
                                              tags: [ "env:#{Rails.env}" ])
  BarkMQ.publisher_config do |c|
    c.logger = Rails.logger
    c.topic_prefix = [ Rails.env, 'barkbox' ].join('-')
    c.statsd = statsd_client

    # Optional but recommended.
    c.middleware.add BarkMQ::Middleware::DatadogLogger, namespace: 'publisher',
                                                        logger: Rails.logger,
                                                        statsd: statsd_client
  end

  BarkMQ.subscriber_config do |c|
    c.logger = Rails.logger
    c.topic_prefix = [ Rails.env, 'barkbox' ].join('-')
    c.statsd = statsd_client

    # Optional but recommended.
    c.middleware.add BarkMQ::Middleware::DatadogLogger, namespace: 'subscriber',
                                                        logger: Rails.logger,
                                                        statsd: statsd_client
  end
```

## Usage

### Publisher

Add `acts_as_publisher` to any ActiveRecord model to enable publisher capabilities.

By default the create, update, and destroy events are enabled.

The create, update, and destroy events also fire a callback where custom logic can be entered. The callback methods will be named `after_<event>_callback`.

To add custom events add the event name to the events param. The topic names will be named `<topic_prefix>-<event>`.

You can specify a custom serializer by passing a ActiveSerializer object as a `serializer` argument.

```ruby
class User < ActiveRecord::Base
  acts_as_publisher events: [ :registered, :email_changed ],
                    serializer: Api::V2::Internal::UserSerializer

  def after_create_callback
    self.publish_to_sns('registered')
  end

  def after_update_callback
    if self.email.present? && self.previous_changes.key?(:email)
      self.publish_to_sns('email_changed')
    end
  end
end
```

### Subscriber

To create a worker that listens to a specific SNS topic include `BarkMQ::Subscriber` and call the `barkmq_subscriber_options` method.

The `perform` method must be implemented as show below or an exception will be triggered.

The execution is synchronous so if it's time intensive pass it off to a delayed worker.

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
