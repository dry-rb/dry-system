---
title: Settings
layout: gem-single
name: dry-system
---

## Basic usage

Dry-system provides a built-in `:settings` component which you can use in your application. In order to set it up, simply define a bootable `:settings` component and import it from the `:system` provider:

```ruby
# in system/boot/settings.rb
require "dry/system/components"
require "path/to/dry/types/file"

Application.boot(:settings, from: :system) do
  settings do
    key :database_url, Types::String.constrained(filled: true)
    key :logger_level, Types::Symbol.constructor(proc { |value| value.to_s.downcase.to_sym })
                                    .default(:info)
                                    .enum(:trace, :unknown, :error, :fatal, :warn, :info, :debug)
  end
end
```

Now, dry-system will map values from `ENV` variable to `settings` struct and allows you to use it in the application:

```ruby
Application[:settings] # => dry-struct object with settings
```

You can also use settings object in other bootable dependencies:

```ruby
Application.boot(:redis) do |container|
  init do
    use :settings

    uri = URI.parse(container[:settings].redis_url)
    redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)

    container.register('persistance.redis', redis)
  end
end
```

Or use `:settings` as an injectible dependency in your classes:

```ruby
  module Operations
    class CreateUser
      include Import[:settings, :repository]

      def call(id:)
        settings # => dry-struct object with settings

        # ...
      end
    end
  end
end
```

## Default values

You can [use dry-types](https://dry-rb.org/gems/dry-types/master/default-values/) for provide default value for specific setting:

```ruby
settings do
  key :redis_url, Types::Coercible::String.default('')
end
```

In this case, if you don't have `ENV['REDIS_URL']` value, you get `''` as the default value for `settings.redis_url` calls.
