# Publisher

By default the create, update, and destroy events are enabled.

You can specify a custom serializer by passing a ActiveSerializer object as a `serializer` argument.

A custom method can be executed after a successful publishing of a `created`, `update`, and `destroy` event by using the `after_publish` method. The options are `event` and `on` as shown below.

## Methods

### acts_as_publisher

### after_publish
