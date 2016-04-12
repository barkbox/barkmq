# Publisher


## acts_as_publisher

Adding `acts_as_publisher` to an ActiveRecord model cause it to publish itself to an SNS topic after changes to the record.

```ruby
acts_as_publisher on: [ :create, :update ],
                  serializer: UserSerializer
```

### on
Optional. Array. Default: `[ :create, :update, :destroy ]`.

Publish ActiveRecord model on these `after_commit` change events.

### serializer
Optional. ActiveSerializer. Default: `to_json`.

An ActiveSerializer that serializes the ActiveRecord model before publishing to an SNS topic.


## after_publish

You can specify custom behavior upon the successful publishing of `create, :update, and :destroy` publish events using the `after_publish` method.

```ruby
after_publish :publish_registered, topic: 'user_registered',
                                   on: [ :create ],
                                   error: publish_registered_error,
                                   complete: Proc.new { puts "complete: " }

def publish_registered
  self.publish_to_sns('user_registered')
end

def publish_registered_error error
  Rails.logger.error "Publish user registered failed. error=#{error.inspect}"
end
```

### error
Optional. Method or object that responds to call. Default: `nil`

Error handler called when the after_publish callback fails. It accepts the error as an argument.

### complete
Optional. Method or object that responds to call. Default: `nil`

Handler called upon the completion of after publish callbacks.
