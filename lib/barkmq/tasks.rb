namespace :barkmq do
  desc 'Create subscriber queues and subscribe queue to topics'
  task setup: :environment do
    require 'circuitry/provisioning'

    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO

    Circuitry::Provisioning.provision(logger: logger)
  end

  desc "Work circuitry queue"
  task :work => [:environment] do |t, args|
    options = {
      lock: true,
      async: true,
      timeout: 20,
      wait_time: 1,
      batch_size: 10
    }
    database_url = ENV['DATABASE_URL']
    pool_size = options[:batch_size] || 10
    if database_url
      ENV['DATABASE_URL'] = "#{database_url}?pool=#{pool_size}"
      ActiveRecord::Base.establish_connection if defined?(Rails)
    end
    BarkMQ.subscribe!(options)
  end
end
