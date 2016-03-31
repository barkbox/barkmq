require 'virtus'
require 'barkmq/config/shared'

module BarkMQ
  module Config

    class Publisher
      include Virtus::Model
      include Shared

      def middleware
        @middleware ||= Circuitry::Middleware::Chain.new
        yield @middleware if block_given?
        @middleware
      end
    end

  end
end
