---
title: Container
layout: gem-single
name: dry-system
---

Main API of `dry-system` is the abstract container that you inherit from. It allows you to configure basic settings and exposes APIs for requiring files easily. Container is the entry point to your application, and it encapsulates application's state.

Let's say you want to define an application container that will provide a logger:

``` ruby
require 'dry/system/container'

class Application < Dry::System::Container
  configure do |config|
    config.root = Pathname('./my/app')
  end
end

# now you can register a logger
require 'logger'
Application.register('utils.logger', Logger.new($stdout))

# and access it
Application['utils.logger']
```

### Auto-Registration

By using simple naming conventions we can automatically register objects within our container.

Let's provide a custom logger object and put it under a custom load-path that we will configure:

``` ruby
require 'dry/system/container'

class Application < Dry::System::Container
  configure do |config|
    config.root = Pathname('./my/app')

    # we set 'lib' relative to `root` as a path which contains class definitions
    # that can be auto-registered
    config.auto_register = 'lib'
  end

  # this alters $LOAD_PATH hence the `!`
  load_paths!('lib')
end

# under /my/app/lib/logger.rb we put
class Logger
  # some neat logger implementation
end

# we can finalize the container which triggers auto-registration
Application.finalize!

# the logger becomes available
Application['logger']
```
