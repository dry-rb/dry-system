# dry-component <a href="https://gitter.im/dryrb/chat" target="_blank">![Join the chat at https://gitter.im/dryrb/chat](https://badges.gitter.im/Join%20Chat.svg)</a>

<a href="https://rubygems.org/gems/dry-component" target="_blank">![Gem Version](https://badge.fury.io/rb/dry-component.svg)</a>
<a href="https://travis-ci.org/dryrb/dry-component" target="_blank">![Build Status](https://travis-ci.org/dryrb/dry-component.svg?branch=master)</a>
<a href="https://gemnasium.com/dryrb/dry-component" target="_blank">![Dependency Status](https://gemnasium.com/dryrb/dry-component.svg)</a>
<a href="https://codeclimate.com/github/dryrb/dry-component" target="_blank">![Code Climate](https://codeclimate.com/github/dryrb/dry-component/badges/gpa.svg)</a>
<a href="http://inch-ci.org/github/dryrb/dry-component" target="_blank">![Documentation Status](http://inch-ci.org/github/dryrb/dry-component.svg?branch=master&style=flat)</a>

Sane dependency management system allowing you to configure reusable components
in any environment, set up their load-paths, require needed files and instantiate
objects automatically with the ability to have them injected as dependencies.

Originally built for [rodakase](https://github.com/solnic/rodakase) stack, now as
a standalone, small library.

This is a simple system that relies on very basic mechanisms provided by Ruby,
specifically `require` and managing `$LOAD_PATH`. It does not rely on any magic
like automatic const resolution, it's pretty much the opposite and forces you to
be explicit about dependencies in your applications.

It does a couple of things for you that are really not something you want to do
yourself:

* Provides an abstract dependency container implementation
* Handles `$LOAD_PATH` configuration
* Loads needed files using `require`
* Resolves dependencies automatically
* Supports auto-registration of dependencies via file/dir naming conventions
* Provides support for custom configuration loaded from external sources (ie YAML)

To put it all together, this allows you to configure your system in a way where
you have full control over dependencies and it's very easy to draw the boundaries
between individual components.

This comes with a bunch of nice benefits:

* Your system relies on abstractions rather than concrete classes and modules
* It helps in decoupling your code from 3rd party code
* It makes it possible to load components in complete isolation. In example you
  can run a single test for a single component and only required files will be
  loaded, or you can run a rake task and it will only load the things it needs.
* It opens up doors for better instrumentation and debugging tools

## Container

Main API is the abstract container that you inherit from. It allows you to configure
basic settings and exposes APIs for requiring files easily.

Let's say you want to define an application container that will provide a logger:

``` ruby
require 'dry/component/container'

class Application < Dry::Component::Container
  configure do |config|
    config.root = '/my/app'
  end
end

# now you can register a logger
require 'logger'
Application.register('utils.logger', Logger.new($stdout))

# and access it
Application['utils.logger']
```

## Auto-Registration

By using simple naming conventions we can automatically register objects within
our container.

Let's provide a custom logger object and put it under a custom load-path that we
will configure:

``` ruby
require 'dry/component/container'

class Application < Dry::Component::Container
  configure do |config|
    config.root = '/my/app'

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

## Auto-Import Mechanism

After defining a container, we can use its import module that will inject object
dependencies automatically.

Let's say we have an object that will need a logger:

``` ruby
# let's define an import module
Import = Application.import_module

# in a class definition you simply specify what it needs
class PostPublisher
  include Import['utils.logger']

  def call(post)
    # some stuff
    logger.debug("post published: #{post}")
  end
end
```

## Directory Structure

You need to provide a specific directory/file structure but names of directories
are configurable. The default is as follows:

```
#{root}
  |- core
    |- boot
      # arbitrary files that are automatically loaded on finalization
```

## Booting a Dependency

In some cases a dependency can be huge, so huge it needs to load some additional
files (often 3rd party code) and it may rely on custom configuration.

Because of this reason `dry-component` has the concept of booting a dependency.

The convention is pretty simple. You put files under `boot` directory and use
your container to register dependencies with the ability to postpone finalization.
This gives us a way to define what's needed but load it and boot it on demand.

Here's a simple example:

``` ruby
# under /my/app/boot/heavy_dep.rb

Application.finalize(:persistence) do
  # some 3rd-party dependency
  require '3rd-party/database'

  container.register('database') do
    # some code which initializes this thing
  end
end
```

After defining the finalization block our container will not call it until its
own finalization. This means we can require file that defines our container
and ask it to boot *just that one :persistence dependency*:

``` ruby
# under /my/app/boot/container.rb
class Application < Dry::Component::Container
  configure do |config|
    config.root = '/my/app'
  end
end

Application.boot!(:persistence)

# and now `database` becomes available
Application['database']
```

## Environment & Providing Arbitrary Options

In most of the systems you need some kind of options for your runtime. Typically
it's provided via ENV vars or a yaml file in development mode. `dry-component`
has a built-in support for this.

You can simply put a file under `#{root}/config/application.yml` and it will be
loaded:

``` yaml
# /my/app/config/application.yml
development:
  foo: 'bar'
```

Now let's configure our container for a specific env:

``` ruby
class Application < Dry::Component::Container
  configure('development') do |config|
    config.root = '/my/app'
  end
end

# now our application options are available
Application.options.foo # => "bar"
```

## Underlying Tools

`dry-component` uses [dry-container](https://github.com/dryrb/dry-container) and
[dry-auto_inject](https://github.com/dryrb/dry-auto_inject) under the hood. These
gems are very small and simple with a total 254LOC. Just saying.

## LICENSE

See `LICENSE` file.
