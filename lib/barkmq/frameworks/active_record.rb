require 'barkmq/acts_as_publisher'

ActiveSupport.on_load(:active_record) do
  include BarkMQ::ActsAsPublisher
end
