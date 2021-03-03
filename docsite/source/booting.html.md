---
title: Booting a Dependency
layout: gem-single
name: dry-system
---

In some cases a dependency can be huge, so huge it needs to load some additional files (often 3rd party code) and it may rely on custom configuration.

Because of this reason dry-system has the concept of booting a dependency.

The convention is pretty simple. You put files under `system/boot` directory and use your container to register dependencies with the ability to postpone finalization. This gives us a way to define what's needed but load it and boot it on demand.

Here's a simple example:

``` ruby
# system/boot/persistence.rb

Application.boot(:persistence) do
  init do
    require '3rd_party/db'
  end

  start do
    register(:database, 3rdParty::Db.new)
  end
end
```

After defining the finalization block our container will not call it until its own finalization. This means we can require file that defines our container and ask it to boot *just that one :persistence dependency*:

``` ruby
# system/application/container.rb
class Application < Dry::System::Container
  configure do |config|
    config.root = Pathname('/my/app')
  end
end

Application.start(:persistence)

# and now `database` becomes available
Application['database']
```

### Lifecycles

In some cases, a bootable dependency may have multiple stages of initialization, to support it dry-system provides 3 levels of booting:

* `init` - basic setup code, here you can require 3rd party code and perform basic configuration
* `start` - code that needs to run for a component to be usable at application's runtime
* `stop` - code that needs to run to stop a component, ie close a database connection, clear some artifacts etc.

Here's a simple example:

``` ruby
# system/boot/db.rb

Application.boot(:db) do
  init do
    require '3rd_party/db'

    register(:db, 3rdParty::Db.configure(ENV['DB_URL']))
  end

  start do
    db.establish_connection
  end

  stop do
    db.close_connection
  end
end
```

### Using other bootable dependencies

It is often needed to use another dependency when booting a component, you can use a convenient `use` API for that, it will auto-boot required dependency
and make it available in the booting context:

``` ruby
# system/boot/logger.rb
Application.boot(:logger) do
  init do
    require 'logger'
  end

  start do
    register(:logger, Logger.new($stdout))
  end
end

# system/boot/db.rb
Application.boot(:db) do |app|
  start do
    use :logger

    register(DB.new(ENV['DB_URL'], logger: app[:logger]))
  end
end
```
