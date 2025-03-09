---
title: Hooks
layout: gem-single
name: dry-system
---

There are a few lifecycle events that you can hook into if you need to ensure things happen in a particular order.

Hooks are executed within the context of the container instance.

### `configure` Event

You can register a callback to fire after the container is configured, which happens one of three ways:

1. The `configure` method is called on the container
2. The `configured!` method is called
3. The `finalize!` method is called when neither of the other two have been

```ruby
class MyApp::Container < Dry::System::Container
  after(:configure) do
    # do something here
  end
end
```

### `register` Event

Most of the time, you will know what keys you are working with ahead of time. But for certain cases you may want to
react to keys dynamically.

```ruby
class MyApp::Container < Dry::System::Container
  use :monitoring

  after(:register) do |key|
    next unless key.end_with?(".gateway")

    monitor(key) do |event|
      resolve(:logger).debug(key:, method: event[:method], time: event[:time])
    end
  end
end
```

Now let's say you register `api_client.gateway` into your container. Your API methods will be automatically monitored
and their timing measured and logged.

### `finalize` Event

Finalization is the point at which the container is made ready, such as booting a web application.

The following keys are loaded in sequence:

1. Providers
2. Auto-registered components
3. Manually-registered components
4. Container imports

At the conclusion of this process, the container is frozen thus preventing any further changes. This makes the
`finalize` event quite important: it's the last call before your container will disallow mutation.

Unlike the previous events, you can register before hooks in addition to after hooks.

The after hooks will run immediately prior to the container freeze. This allows you to enumerate the container keys
while they can still be mutated, such as with `decorate` or `monitor`.

```ruby
class MyApp::Container < Dry::System::Container
  before(:finalize) do
    # Before system boot, no keys registered yet
  end

  after(:finalize) do
    # After system boot, all keys registered
  end
end
```
