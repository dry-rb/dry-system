---
title: Plugins
layout: gem-single
name: dry-system
---

Dry-system has already built-in plugins that you can enable, and it’s very easy to write your own. 

## Logging support

You can now enable a default system logger by simply enabling `:logging` plugin, you can also configure log dir, level and provide your own logger class.

```ruby
class App < Dry::System::Container
  use :logging
end

# default logger is registered as a standard object, so you can inject it via auto-injection
App[:logger]

# short-cut method is provided too, which is convenient in some cases
App.logger           
```

## Zeitwerk

With `:zeitwerk` plugin you can easily use [Zeitwerk](https://github.com/fxn/zeitwerk) as your applications's code loader.

> Given a conventional file structure, Zeitwerk is able to load your project's classes and modules on demand (autoloading), or upfront (eager loading). You don't need to write require calls for your own files, rather, you can streamline your programming knowing that your classes and modules are available everywhere. This feature is efficient, thread-safe, and matches Ruby's semantics for constants. (Zeitwerk docs)

### Example

Here is an example of using Zeitwerk plugin:

```ruby
class App < Dry::System::Container
  use :zeitwerk # magic!

  configure do |config|
    config.component_dirs.add "lib"
  end
end
```

For a more in depth and runnable example, [click here](https://github.com/dry-rb/dry-system/tree/master/examples/standalone).

### Inflections 

The plugin tries to handle most of the plumbing for you. For example, is uses the container's own inflector to resolve constant names. So if Zeitwerk is having trouble resolving some constants, just update the container's inflector like so:

```ruby
class App < Dry::System::Container
  use :zeitwerk 

  configure do |config|
    config.inflector = Dry::Inflector.new do |inflections|
      inflections.acronym('API')
    end

    # ...
  end
end
```

### Advanced Configuration

If you find you need to adjust Zeitwerk configuration, you can do so by accessing the `Zeitwerk::Loader` instance directly on the container.

```ruby
# After you have configured the container

MyContainer.autoloader.eager_load
```



## Monitoring

Another plugin is called `:monitoring` which allows you to enable object monitoring, which is built on top of dry-monitor’s instrumentation API. Let’s say you have an object registered under `"users.operations.create",` and you’d like to add additional logging:

```ruby
class App < Dry::System::Container
  use :logging
  use :monitoring
end

App.monitor("users.operations.create") do |event|
  App.logger.debug "user created: #{event.payload} in #{event[:time]}ms"
end
```

You can also provide specific methods that should be monitored, let’s say we’re only interested in `#call` method:

```ruby
App.monitor("users.operations.create", methods: %i[call]) do |event|
  App.logger.debug "user created: #{event.payload} in #{event[:time]}ms"
end
```

## Setting environment

Environment can now be set in a non-web systems too. Previously this was only possible in dry-web, now any ruby app based on dry-system can use this configuration setting via `:env` plugin:

```ruby
class App < Dry::System::Container
  use :env

  configure do |config|
    config.env = :staging
  end
end
```

You can provide environment inferrer, which is probably something you want to do, here’s how dry-web sets up its environment:

```ruby
module Dry
  module Web
    class Container < Dry::System::Container
      use :env, inferrer: -> { ENV.fetch("RACK_ENV", :development).to_sym }
    end
  end
end
```

## Experimental bootsnap support

dry-system is already pretty fast, but in a really big apps, it can take over 2 seconds to boot. You can now speed it up significantly by using `:bootsnap` plugin, which simply configures bootsnap for you:

```ruby
class App < Dry::System::Container
  use :bootsnap # that's it
end
```

We’ve noticed a ~30% speed boost during booting the entire app, unfortunately there are some problems with bootsnap + byebug, so it is now recommended to turn it off if you’re debugging something.
