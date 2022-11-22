---
title: Providers
layout: gem-single
name: dry-system
---

Some components can be large, stateful, or requiring specific configuration as part of their setup (such as when dealing with third party code). You can use providers to manage and register these components across several distinct lifecycle steps.

You can define your providers as individual source files in `system/providers/`, for example:

``` ruby
# system/providers/persistence.rb

Application.register_provider(:database) do
  prepare do
    require "third_party/db"
  end

  start do
    register(:database, ThirdParty::DB.new)
  end
end
```

The provider’s lifecycle steps will not run until the provider is required by another component, is started directly, or when the container finalizes.

This means you can require your container and ask it to start just that one provider:

``` ruby
# system/application/container.rb
class Application < Dry::System::Container
  configure do |config|
    config.root = Pathname("/my/app")
  end
end

Application.start(:database)

# and now `database` becomes available
Application["database"]
```

### Provider lifecycle

The provider lifecycle consists of three steps, each with a distinct purpose:

* `prepare` - basic setup code, here you can require third party code and perform basic configuration
* `start` - code that needs to run for a component to be usable at application's runtime
* `stop` - code that needs to run to stop a component, ie close a database connection, clear some artifacts etc.

Here's a simple example:

``` ruby
# system/providers/db.rb

Application.register_provider(:database) do
  prepare do
    require 'third_party/db'

    register(:database, ThirdParty::DB.configure(ENV['DB_URL']))
  end

  start do
    container[:database].establish_connection
  end

  stop do
    container[:database].close_connection
  end
end
```

### Using other providers

You can start one provider as a dependency of another by invoking the provider’s lifecycle directly on the `target` container (i.e. your application container):

``` ruby
# system/providers/logger.rb
Application.register_provider(:logger) do
  prepare do
    require "logger"
  end

  start do
    register(:logger, Logger.new($stdout))
  end
end

# system/providers/db.rb
Application.register_provider(:db) do
  start do
    target.start :logger

    register(DB.new(ENV['DB_URL'], logger: target[:logger]))
  end
end
```
