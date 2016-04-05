require 'barkmq/publisher'

ActiveSupport.on_load(:active_record) do
  include BarkMQ::Publisher
  include BarkMQ::ActsAsPublisher
end
