---
title: Dependency auto-injection
layout: gem-single
name: dry-system
---

After defining your container, you can use its auto-injector as a mixin to declare a component's dependencies using their container keys.

For example, if you have an `Application` container and an object that will need a logger:

``` ruby
# system/import.rb
require "system/container"
Import = Application.injector

# In a class definition you simply specify what it needs
# lib/post_publisher.rb
require "import"
class PostPublisher
  include Import["logger"]

  def call(post)
    # some stuff
    logger.debug("post published: #{post}")
  end
end
```

### Auto-registered component keys

When components are auto-registered, their default keys are based on their file paths and your [component dir](docs::component-dirs) configuration. For example, `lib/api/client.rb` will have the key `"api.client"` and will resolve an instance of `API::Client`.

Resolving a component will also start a registered [provider](docs::providers) if it shares the same name as the root segment of its container key. This is useful in cases where a group of components require an additional dependency to be always made available.

For example, if you have a group of repository objects that need a `persistence` provider to be started, all you need to do is to follow this naming convention:

- `system/providers/persistence.rb` - where you register your `:persistence` provider
- `lib/persistence/user_repo` - where you can define any components that need the components or setup established by the `persistence` provider

Here's a sample setup for this scenario:

``` ruby
# system/container.rb
require "dry/system"

class Application < Dry::System::Container
  configure do |config|
    config.root = Pathname("/my/app")
    config.component_dirs.add "lib"
  end
end

# system/import.rb
require_relative "container"

Import = Application.injector

# system/providers/persistence.rb
Application.register_provider(:persistence) do
  start do
    require "sequel"
    container.register("persistence.db", Sequel.connect(ENV['DB_URL']))
  end

  stop do
    container["persistence.db"].disconnect
  end
end

# lib/persistence/user_repo.rb
require "import"

module Persistence
  class UserRepo
    include Import["persistence.db"]

    def find(conditions)
      db[:users].where(conditions)
    end
  end
end
```
