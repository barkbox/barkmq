require 'virtus'
require 'barkmq/config/shared'

module BarkMQ
  module Config

    class Publisher
      include Virtus::Model
      include Shared

      attribute :middleware
    end
  end
end
