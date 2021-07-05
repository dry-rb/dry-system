---
title: Component Providers
layout: gem-single
name: dry-system
---

External dependencies can be provided as bootable components, these components can be shared across applications with the ability to configure them and customize booting process. This is especially useful in situations where you have a set of applications with many common components.

Bootable components are handled by component providers, which can register themselves and set up their components. Let's say we want to provide a common exception notifier for many applications. First, we register our provider called `:common`:

``` ruby
# my_gem
#  |- lib/my_gem/components.rb

Dry::System.register_provider(
  :common,
  boot_path: Pathname(__dir__).join('boot').realpath()
)
```

Then we define our component:

``` ruby
# my_gem
#  |- lib/my_gem/boot/exception_notifier.rb
Dry::System.register_component(:exception_notifier, provider: :common) do
  init do
    require "some_exception_notifier"
  end
  
  start do
    register(:exception_notifier, SomeExceptionNotifier.new)
  end
end
```

Now in application container we can easily boot this external component:

``` ruby
# system/app/container.rb
require "dry/system/container"
require "my_gem/components"

module App
  class Container < Dry::System::Container
    boot(:exception_notifier, from: :common)
  end
end

App::Container[:exception_notifier]
```

### Hooking into booting process

You can use lifecycle before/after callbacks if you need to do something special. For instance, you may want to customize object registration, for this you can use `after(:start)` callback, which receives a container that was set up by your `:common` component provider:

``` ruby
module App
  class Container < Dry::System::Container
    boot(:exception_notifier, from: :common) do
      after(:start) do |common|
        register(:notifier, common[:exception_notifier])
      end
    end
  end
end
```

Following callbacks are supported:

- `before(:init)`
- `after(:init)`
- `before(:start)`
- `after(:start)`

### Providing component configuration

Components can specify their configuration settings using `settings` block, settings specify keys and types, and default values can be set too. If a component uses settings, then lifecycle steps have access to its `config`.

Here's an extended `:exception_notifier` example which uses its own settings:

``` ruby
# my_gem
#  |- lib/my_gem/boot/exception_notifier.rb
Dry::System.register_component(:exception_notifier, provider: :common) do
  settings do
    setting :environments, Types::Strict::Array.of(Types::Strict::Symbol).default(%i[production])
    setting :logger, Types::Any
  end

  init do
    require "some_exception_notifier"
  end
  
  start do
    # now we have access to `config`
    register(:exception_notifier, SomeExceptionNotifier.new(config.to_h))
  end
end
```

In this example we define two config keys:

- `:environments` which is a list of environment identifiers with default value set to `[:production]`
- `:logger` an object that should be used as the logger, which must be configured

In order to configure our `:logger` we simply use `configure` block when registering the component:

``` ruby
module App
  class Container < Dry::System::Container
    boot(:exception_notifier, from: :common) do
      after(:init) do
        require "logger"
      end
      
      configure do |config|
        config.logger = Logger.new($stdout)
      end
    end
  end
end
```
