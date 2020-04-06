---
title: Settings
layout: gem-single
name: dry-system
---

## Basic usage

Dry-system has already built-in settings system which you can use for your application. For this you need to use system component:

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

Or use settings in your logic:

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

You can [use dry-type](https://dry-rb.org/gems/dry-types/master/default-values/) for provide default value for specific setting:

```ruby
settings do
  key :redis_url, Types::Coercible::String.default('')
end
```

In this case, if you don't have `ENV['REDIS_URL']` value you get `''` as a default value for `settings.redis_url` calls
