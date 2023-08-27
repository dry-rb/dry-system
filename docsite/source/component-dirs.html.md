---
title: Component dirs
layout: gem-single
name: dry-system
---

The container auto-registers its components from one or more component dirs, the directories holding the Ruby source files for your classes.

You can configure one or more component dirs:

```ruby
class Application < Dry::System::Container
  configure do |config|
    config.root = __dir__

    config.component_dirs.add "lib"
    config.component_dirs.add "app"
  end
end
```

Component dirs will be searched in the order you add them. A component found in the first added dir will be registered in preference to a component with the same name in a later dir.

### Component dir configuration

You can configure many aspects of component auto-registration via component dirs.

#### auto_register

`auto_register` sets the auto-registration policy for the component dir.

This may be a simple boolean to enable or disable auto-registration for all components, or a proc accepting a `Dry::Sytem::Component` and returning a boolean to configure auto-registration on a per-component basis.

`auto_register` defaults to `true`.

```ruby
config.component_dirs.add "lib" do |dir|
  dir.auto_register = false
end
```

```ruby
config.component_dirs.add "lib" do |dir|
  dir.auto_register = proc do |component|
    !component.identifier.start_with?("entities")
  end
end
```

#### memoize

`memoize` sets whether to memoize components from the dir when registered in the container (ordinarily, components are initialized every time they are resolved).

This may be a simple boolean to enable or disable memoization for all components, or a proc accepting a `Dry::Sytem::Component` and returning a boolean to configure memoization on a per-component basis.

`memoize` defaults to `false`.

```ruby
config.component_dirs.add "lib" do |dir|
  dir.memoize = true
end
```
```ruby
config.component_dirs.add "lib" do |dir|
  dir.memoize = proc do |component|
    component.identifier.start_with?("providers")
  end
end
```

#### namespaces

`namespaces` allows one or more namespaces to be added for paths within the component dir. For the given path, the namespace determines:

1. The leading segments of its components' registered identifiers, and
2. The expected constant namespace of their class constants.

When adding a namespace, you can specify:

- A `key:` namespace, which determines the leading part of the key used to register each component in the container. It can be:
  - Omitted, in which case it defaults to the value of `path`
  - A string, which will become the leading part of the registered keys
  - `nil`, which will make the registered keys top-level, with no additional leading parts
- A `const:` namespace, which is the Ruby namespace expected to contain the class constants defined within each component's source file.

  This value is provided as an "underscored" string, and will be run through the container inflector's `#constantize`, to be converted in to a real constant (e.g. `"foo_bar/baz"` will become `FooBar::Baz`). Accordingly, `const:` can be:
  - Omitted, in which case it defaults to the value of `path`
  - A string, which will be constantized to the expected constant namespace per the rules above
  - `nil`, to indicate the class constants will be in the top-level constant namespace

Only a single namespace can be added for any distinct path.

To illustrate these options:

**Top-level key namespace**

```ruby
config.component_dirs.add "lib" do |dir|
  dir.namespaces.add "admin", key: nil
end
```

- `admin/foo.rb` is expected to define `Admin::Foo`, will be registered as `"foo"`
- `admin/bar/baz.rb` is expected to define `Admin::Bar::Baz`, will be registered as `"bar.baz"`

**Top-level const namespace**

```ruby
config.component_dirs.add "lib" do |dir|
  dir.namespaces.add "admin/top", const: nil
end
```

- `admin/top/foo.rb` is expected to define `Foo`, will be registered as `"admin.top.foo"`
- `admin/top/bar/baz.rb` is expected to define `Bar::Baz`, will be registered as `"admin.top.bar.baz"`

**Distinct const namespace**

```ruby
config.component_dirs.add "lib" do |dir|
  dir.namespaces.add "admin", key: nil, const: "super/admin"
end
```

- `admin/foo.rb` is expected to define `Super::Admin::Foo`, will be registered as `"foo"`
- `admin/bar/baz.rb` is expected to define `Super::Admin::Bar::Baz`, will be registered as `"bar.baz"`

**Omitted key namespace, with keys keeping their natural prefix**

```ruby
config.component_dirs.add "lib" do |dir|
  dir.namespaces.add "admin", const: "super/admin"
end
```

- `admin/foo.rb` is expected to define `Super::Admin::Foo`, will be registered as `"admin.foo"`
- `admin/bar/baz.rb` is expected to define `Super::Admin::Bar::Baz`, will be registered as `"admin.bar.baz"`

##### Each component dir may have multiple namespaces

The examples above show a component dir with a single configured namespace, but component dir may have any number of namespaces:

```ruby
config.component_dirs.add "lib" do |dir|
  dir.namespaces.add "admin/system_adapters", key: nil, const: nil
  dir.namespaces.add "admin", key: nil
  dir.namespaces.add "elsewhere", key: "stuff.and.things"
end
```

When the container loads its components, namespaces are searched and evaluated in order of definition. So for the example above:

- Files within `lib/admin/system_adapters/` will have the `key: nil, const: nil` namespace rules applied
- All other files in `lib/admin/` will have the `key: nil` namespace rules applied
- Files in `lib/elsewhere/` will have the `key: "stuff.and.things"` namespace rules applied

##### A root namespace is implicitly appended to a component dir's configured namespaces

To ensure that all the the files within a component dir remain loadable, a "root namespace" is implicitly appended to the list of configured namespaces on a component dir.

A root namespace, as the name implies, encompasses all files in the component dir. In the example above, the root namespace would be used when loading files _not_ in the `admin/` or `elsewhere/` paths.

The default root namespace is effectively the following:

```ruby
namespaces.add nil, key: nil, const: nil
```

It has `nil` path (the root of the component dir), a `nil` leading key namespace (all keys will be determined based on the full file path from the root of the dir), and a `nil` const namespace (implying that the root of the component dir will hold top-level constants).

These assumptions tend to hold true for typically organised projects, and they ensure that the component dirs can load code usefully even when no namespaces are configured at all.

##### The root namespace may be explicitly configured

There may be cases where you want different namespace rules to apply when loading components from the root of the component dir. To support this, you can configure the root namespace explicitly via `namespaces.root`.

In this example, files in `lib/` are all expected to provide class constants in the `Admin` namespace:

```ruby
config.component_dirs.add "lib" do |dir|
  dir.namespaces.root const: "admin"
end
```

Root namespaces can be configured alongside other namespaces. The same namespace ordering preferences apply to root namespaces as to all others.

#### add_to_load_path

`add_to_load_path` sets whether the component dir should be added to the `$LOAD_PATH` after the container is configured.

Set this to false if you’re using dry-container with an autoloader.

`add_to_load_path` defaults to `true`.

#### loader

`loader` sets the loader to use when registering components from the dir in the container.

`loader` defaults to `Dry::System::Loader`.

When using a class autoloader, consider setting this to `Dry::System::Loader::Autoloading`:

```ruby
require "dry/system"

class Application < Dry::System::Container
  configure do |config|
    config.root = __dir__

    config.component_dirs.add "lib" do |dir|
      dir.loader = Dry::System::Loader::Autoloading
    end
  end
end
```

To provide a custom loader, you must implement the same interface as `Dry::System::Loader`.

### Component dir defaults configuration

If you are adding multiple component dirs to your container, and would like common configuration to be applied to all of them, you can configure the `component_dirs` collection directly.

Configuration set on `component_dirs` will be applied to all added component dirs. Any configuration applied directly to an individual component dir will override the defaults.

```ruby
class MyApp::Container < Dry::System::Container
  configure do |config|
    config.root = __dir__

    # Configure defaults for all component dirs
    config.component_dirs.auto_register = proc do |component|
      !component.identifier.start_with?("entities")
    end
    config.component_dirs.namespaces.add "admin", key: nil

    config.component_dirs.add "lib"
    config.component_dirs.add "app"
  end
end
```

### Inline component configuration with magic comments

You can override certain aspects of the component dir configuration on a per-component basis by adding “magic comments” to the top of your source files.

The following settings can be configured by magic comments:

- `auto_register`
- `memoize`

In the magic comments, you can set `true` or `false` values only.

For example, to disable auto-registration of a particular component:

```ruby
# auto_register: false
# frozen_string_literal: true

class MyClass
end
```

Or to enable memoization of a particular component:

```ruby
# memoize: true
# frozen_string_literal: true

class MyClass
end
```
