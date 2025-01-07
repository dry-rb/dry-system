---
title: External provider sources
layout: gem-single
name: dry-system
---

You can distribute your own components to other dry-system users via external provider sources, which can be used as the basis for providers within any dry-system container.

Provider sources look and work the same as regular providers, which means allowing you to use their full lifecycle for creating, configuring, and registering your components.

To distribute a group of provider sources (defined in their own files), register them with `Dry::System`:

``` ruby
# my_gem
#  |- lib/my_gem/provider_sources.rb

Dry::System.register_provider_sources(:common, boot_path: File.join(__dir__, "provider_sources"))
```

Then, define your provider source:

``` ruby
# my_gem
#  |- lib/my_gem/provider_sources/exception_notifier.rb

Dry::System.register_provider_source(:exception_notifier, group: :my_gem) do
  prepare do
    require "some_exception_notifier"
  end

  start do
    register(:exception_notifier, SomeExceptionNotifier.new)
  end
end
```

Then you can use this provider source when you register a provider in a dry-system container:

``` ruby
# system/app/container.rb

require "dry/system"
require "my_gem/provider_sources"

module App
  class Container < Dry::System::Container
    register_provider(:exception_notifier, from: :my_gem)
  end
end

App::Container[:exception_notifier]
```

### Customizing provider sources

You can customize a provider source for your application via `before` and `after` callbacks for its lifecycle steps.

For example, you can register additional components based on the provider source's own registrations via an `after(:start)` callback:

``` ruby
module App
  class Container < Dry::System::Container
    register_provider(:exception_notifier, from: :my_gem) do
      after(:start)
        register(:my_notifier, container[:exception_notifier])
      end
    end
  end
end
```

The following callbacks are supported:

- `before(:prepare)`
- `after(:prepare)`
- `before(:start)`
- `after(:start)`

### Providing component configuration

Provider sources can define their own settings using [dry-configurable’s](/gems/dry-configurable) `setting` API. These will be configured when the provider source is used by a provider. The other lifecycle steps in the provider souce can access the configured settings as `config`.

For example, here’s an extended `:exception_notifier` provider source with settings:

``` ruby
# my_gem
#  |- lib/my_gem/provider_sources/exception_notifier.rb

Dry::System.register_component(:exception_notifier, provider: :common) do
  setting :environments, default: :production, constructor: Types::Strict::Array.of(Types::Strict::Symbol)
  setting :logger

  prepare do
    require "some_exception_notifier"
  end

  start do
    # Now we have access to `config`
    register(:exception_notifier, SomeExceptionNotifier.new(config.to_h))
  end
end
```

This defines two settings:

- `:environments`, which is a list of environment identifiers with default value set to `[:production]`
- `:logger`, an object that should be used as the logger, which must be configured

To configure this provider source, you can use a `configure` block when defining your provider using the source:

``` ruby
module App
  class Container < Dry::System::Container
    register_provider(:exception_notifier, from: :my_gem) do
      require "logger"

      configure do |config|
        config.logger = Logger.new($stdout)
      end
    end
  end
end
```
