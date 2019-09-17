# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'barkmq/version'

Gem::Specification.new do |spec|
  spec.name          = "barkmq"
  spec.version       = BarkMQ::VERSION
  spec.authors       = ["Cris Kim"]
  spec.email         = ["cris@criskim.com"]

  spec.summary       = %q{BarkMQ is a gem to faciliate publishing/subscribing to topics.}
  spec.description   = %q{BarkMQ is an opinionated wrapper to circuitry with publish and subscribe to SNS/SQS. It also contains sensible instrumentation to DataEdog.}
  spec.homepage      = "https://github.com/barkbox/barkmq"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "virtus", "~> 1.0"
  spec.add_dependency "circuitry", "~> 3.1.3"
  spec.add_dependency "dogstatsd-ruby", "~> 1.6.0"
  spec.add_dependency "shoryuken", "~> 2.0.4"
  spec.add_dependency "celluloid", "~> 0.17.3"
  spec.add_dependency "retries", "~> 0.0.5"
  spec.add_dependency "sidekiq", "< 6"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "redis"
  spec.add_development_dependency "activerecord", "~> 3.0"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "coveralls"

end
