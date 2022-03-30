# 1.0.1
- Fix bug caused by Shoryuken update

# 1.0.0
- Configure CircleCI to run specs
- Fix specs
  - `Statsd.new` -> `Datadog::Statsd.new`
  - Update expectation to include `after_publish_on_complete`
- Update `activerecord`, `~> 3.0` to `>= 5, < 6.2`
- Update `circuitry`, `~> 3.1.3` to `~> 3.4`
- Update `shoryuken`, `~> 2.0.4` to `< 6`

# 0.6.1
- Update `sidekiq` from `< 5` to `< 6`
- Update `dogstatsd-ruby` from `~> 1.6.0` to `~> 3.3.0`
