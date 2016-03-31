require 'rails'

module BarkMQ
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'barkmq/tasks.rb'
    end
  end
end
