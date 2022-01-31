---
title: Plugins
layout: gem-single
name: dry-system
---

dry-system has already built-in plugins that you can enable, and it’s very easy to write your own.

## Zeitwerk

With the `:zeitwerk` plugin you can easily use [Zeitwerk](https://github.com/fxn/zeitwerk) as your applications's code loader:

> Given a conventional file structure, Zeitwerk is able to load your project's classes and modules on demand (autoloading), or upfront (eager loading). You don't need to write require calls for your own files, rather, you can streamline your programming knowing that your classes and modules are available everywhere. This feature is efficient, thread-safe, and matches Ruby's semantics for constants. (Zeitwerk docs)

### Example

Here is an example of using Zeitwerk plugin:

```ruby
class App < Dry::System::Container
  use :env, inferrer: -> { ENV.fetch("RACK_ENV", :development).to_sym }
  use :zeitwerk

  configure do |config|
    config.component_dirs.add "lib"
  end
end
```

For a more in depth and runnable example, [see here](https://github.com/dry-rb/dry-system/tree/master/examples/zeitwerk).

### Inflections

The plugin passes the container's inflector to the Zeitwerk loader for resolving constants from file names. If Zeitwerk has trouble resolving some constants, you can update the container's inflector like so:

```ruby
class App < Dry::System::Container
  use :zeitwerk

  configure do |config|
    config.inflector = Dry::Inflector.new do |inflections|
      inflections.acronym('REST')
    end

    # ...
  end
end
```

### Eager Loading

By default, the plugin will have Zeitwerk eager load when using the `:env` plugin sets the environment to `:production`. However, you can change this behavior by passing `:eager_load` option to the plugin:

```ruby
class App < Dry::System::Container
  use :zeitwerk, eager_load: true
end
```

### Debugging

When you are developing your application, you can enable the plugin's debugging mode by passing `debug: true` option to the plugin, which will print Zeitwerk's logs to the standard output.

```ruby
class App < Dry::System::Container
  use :zeitwerk, debug: true
end
```

### Advanced Configuration

If you need to adjust the Zeitwerk configuration, you can do so by accessing the `Zeitwerk::Loader` instance directly on the container, as `.autoloader`:

```ruby
# After you have configured the container but before you have finalized it

MyContainer.autoloader.ignore("./some_path.rb)
```

## Application environment

You can use the `:env` plugin to set and configure an `env` setting for your application.

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

## Logging

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

## Experimental bootsnap support

dry-system is already pretty fast, but in a really big apps, it can take some seconds to boot. You can now speed it up significantly by using `:bootsnap` plugin, which simply configures bootsnap for you:

```ruby
class App < Dry::System::Container
  use :bootsnap # that's it
end
```

We’ve noticed a ~30% speed boost during booting the entire app, unfortunately there are some problems with bootsnap + byebug, so it is now recommended to turn it off if you’re debugging something.
