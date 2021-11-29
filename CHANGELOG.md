# 1.0-rc1
- Configure CircleCI to run specs
- Fix specs
  - `Statsd.new` -> `Datadog::Statsd.new`
  - Update expectation to include `after_publish_on_complete`
- Update `activerecord`, `>= 5` to `< 6.2`

# 0.6.1
- Update `sidekiq` from `< 5` to `< 6`
- Update `dogstatsd-ruby` from `~> 1.6.0` to `~> 3.3.0`
