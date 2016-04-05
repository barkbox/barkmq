ActiveRecord::Schema.define do
  self.verbose = false

  create_table :new_ar_publishers, :force => true do |t|
    t.string  :event
    t.timestamps
  end
end
