---
title: Settings
layout: gem-single
name: dry-system
---

## Basic usage

dry-system provides a `:settings` provider source that you can use to load settings and share them throughout your application. To use this provider source, create your own `:settings` provider using the provider source from `:dry_system`, then declare your settings inside `settings` block (using [dry-configurable’s](/gems/dry-configurable) `setting` API):

```ruby
# system/providers/settings.rb:

require "dry/system"

Application.register_provider(:settings, from: :dry_system) do
  before :prepare do
    # Change this to load your own `Types` module if you want type-checked settings
    require "your/types/module"
  end

  settings do
    setting :database_url, constructor: Types::String.constrained(filled: true)

    setting :logger_level, default: :info, constructor: Types::Symbol
      .constructor { |value| value.to_s.downcase.to_sym }
      .enum(:trace, :unknown, :error, :fatal, :warn, :info, :debug)
  end
end
```

Your provider will then map `ENV` variables to a struct object giving access to your settings as their own methods, which you can use throughout your application:

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
