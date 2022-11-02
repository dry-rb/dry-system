---
title: Settings
layout: gem-single
name: dry-system
---

## Basic usage

dry-system provides a `:settings` provider source that you can use to load settings and share them throughout your application. To use this provider source, create your own `:settings` provider using the provider source from `:dry_system`, then declare your settings inside `settings` block (using [dry-configurable’s](/gems/dry-configurable) `setting` API):

```ruby
# system/providers/settings.rb:

require "dry/system/provider_sources"

Application.register_provider(:settings, from: :dry_system) do
  before :prepare do
    # Change this to load your own `Types` module if you want type-checked settings
    require "your/types/module"
  end

  configure do |config|
    config.prefix = 'SOME_PREFIX_'
  end

  settings do
    setting :database_url, constructor: Types::String.constrained(filled: true)

    setting :logger_level, default: :info, constructor: Types::Symbol
      .constructor { |value| value.to_s.downcase.to_sym }
      .enum(:trace, :unknown, :error, :fatal, :warn, :info, :debug)
  end
end
```

An optional prefix can be specified with the `config.prefix` setting inside a `configure` block. Your provider will then map `ENV` variables with the given prefix to a struct object giving access to your settings as their own methods, which you can use throughout your application:

```ruby
Application[:settings].database_url # => "postgres://..."
Application[:settings].logger_level # => :info
```

You can use this settings object in other providers:

```ruby
Application.register_provider(:redis) do
  start do
    use :settings

    uri = URI.parse(target[:settings].redis_url)
    redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)

    register('persistance.redis', redis)
  end
end
```

Or as an injected dependency in your classes:

```ruby
  module Operations
    class CreateUser
      include Import[:settings]

      def call(params)
        settings # => your settings struct
      end
    end
  end
end
```

## Multiple Settings Providers

In some situations you may wish to have multiple settings providers registered to different namespaces, e.g `config.database` and `config.api`. This can be achieved using the `register_as` configuration option:

```ruby
# system/providers/database_settings.rb:

require "dry/system/provider_sources"

Application.register_provider(:database_settings, from: :dry_system, source: :settings) do
  before :prepare do
    require "your/types/module"
  end

  configure do |config|
    config.register_as = 'config.database'
  end

  settings do
    setting :url, constructor: Types::String.constrained(filled: true)
  end
end
```

```ruby
# system/providers/api_settings.rb:

require "dry/system/provider_sources"

Application.register_provider(:api_settings, from: :dry_system, source: :settings) do
  before :prepare do
    require "your/types/module"
  end

  configure do |config|
    config.register_as = 'config.api'
  end

  settings do
    setting :base_url, constructor: Types::String.constrained(filled: true)
  end
end
```

The individual settings namespaces can then be accessed from the container seperately:

```ruby
Application.start(:database_settings)
Application.start(:api_settings)
Application['config.database'].url # => "postgres://..."
Application['config.api'].base_url # => "https://..."
```
