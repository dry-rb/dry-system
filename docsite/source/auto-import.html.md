---
title: Auto-Import
layout: gem-single
name: dry-system
---

After defining a container, we can use its import module that will inject object dependencies automatically.

Let's say we have an `Application` container and an object that will need a logger:

``` ruby
# system/import.rb
require 'system/container'
Import = Application.injector

# In a class definition you simply specify what it needs
# lib/post_publisher.rb
require 'import'
class PostPublisher
  include Import['utils.logger']

  def call(post)
    # some stuff
    logger.debug("post published: #{post}")
  end
end
```

### Directory Structure

You need to provide a specific directory/file structure but names of directories are configurable. The default is as follows:

```
#{root}
  |- system
    |- boot
      # arbitrary files that are automatically loaded on finalization
```

### Component identifiers

When components are auto-registered, default identifiers are created based on file paths, ie `lib/api/client` resolves to `API::Client` class with identifier `api.client`.
These identifiers *may have special meaning* where the first name defines its dependency. This is useful for cases where a group of components needs an additional dependency to be always booted for them.

Let's say we have a group of repository objects that need a `persistence` component to be booted - all we need to do is to follow a simple naming convention:

- `system/boot/persistence` - here we finalize `persistence` component
- `lib/persistence/user_repo` - here we define components that needs `persistence`

Here's a sample setup for this scenario:

``` ruby
# system/container.rb
require 'dry/system/container'

class Application < Dry::System::Container
  configure do |config|
    config.name = :app
    config.root = Pathname('/my/app')
    config.auto_register = %w(lib)
  end

  load_paths!('lib')
end

# system/import.rb
require_relative 'container'

Import = Application.injector

# system/boot/persistence.rb
Application.boot(:persistence) do |container|
  start do
    require 'sequel'
    container.register('persistence.db', Sequel.connect(ENV['DB_URL']))
  end

  stop do
    db.disconnect
  end
end

# lib/persistence/user_repo.rb
require 'import'

module Persistence
  class UserRepo
    include Import['persistence.db']

    def find(conditions)
      db[:users].where(conditions)
    end
  end
end
```
