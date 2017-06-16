# 0.7.1 - 2017-06-16

### Changed

- Accept string values for Container's `root` config (timriley)

# 0.7.0 - 2017-06-15

### Added

- Added `manual_registrar` container setting (along with default `ManualRegistrar` implementation), and `registrations_dir` setting. These provide support for a well-established place for keeping files with manual container registrations (timriley)
- AutoRegistrar parses initial lines of Ruby source files for "magic comments" when auto-registering components. An `# auto_register: false` magic comment will prevent a Ruby file from being auto-registered (timriley)
- `Container.auto_register!`, when called with a block, yields a configuration object to control the auto-registration behavior for that path, with support for configuring 2 different aspects of auto-registration behavior (both optional):

    ```ruby
    class MyContainer < Dry::System::Container
      auto_register!('lib') do |config|
        config.instance do |component|
          # custom logic for initializing a component
        end

        config.exclude do |component|
          # return true to skip auto-registration of the component, e.g.
          # component.path =~ /entities/
        end
      end
    end
    ```

- A helpful error will be raised if a bootable component's finalize block name doesn't match its boot file name (GustavoCaso)

### Changed

- The `default_namespace` container setting now supports multi-level namespaces (GustavoCaso)
- `Container.auto_register!` yields a configuration block instead of a block for returning a custom instance (see above) (GustavoCaso)
- `Container.import` now requires an explicit local name for the imported container (e.g. `import(local_name: AnotherContainer)`) (timriley)

[Compare v0.6.0...v0.7.0](https://github.com/dry-rb/dry-system/compare/v0.6.0...v0.7.0)


# 0.6.0 - 2016-02-02

### Changed

* Lazy load components as they are resolved, rather than on injection (timriley)
* Perform registration even though component already required (blelump)

[Compare v0.5.1...v0.6.0](https://github.com/dry-rb/dry-system/compare/v0.5.1...v0.6.0)

# 0.5.1 - 2016-08-23

### Fixed

- Undefined locals or method calls will raise proper exceptions in Lifecycle DSL (aradunovic)

[Compare v0.5.0...v0.5.1](https://github.com/dry-rb/dry-system/compare/v0.5.0...v0.5.1)

# 0.5.0 - 2016-08-15

This is a major refactoring with better internal APIs and improved support
for multi-container setups. As part of this release `dry-system` has been renamed to `dry-system`.

### Added

- Boot DSL with:
  * Lifecycle triggers: `init`, `start` and `stop` (solnic)
  * `use` method which auto-boots a dependency and makes it available in the booting context (solnic)
- When a component relies on a bootable component, and is being loaded in isolation, the component will be booted automatically (solnic)

### Changed

- [BREAKING] `Dry::Component::Container` is now `Dry::System::Container` (solnic)
- [BREAKING] Configurable `loader` is now a class that accepts container's config and responds to `#constant` and `#instance` (solnic)
- [BREAKING] `core_dir` renameda to `system_dir` and defaults to `system` (solnic)
- [BREAKING] `auto_register!` yields `Component` objects (solnic)

### Internal improvements

- Use new `Dry::Container#merge` which accepts `:namespace` option (AMHOL)
- Auto-registration is handled by a `System::AutoRegistrar` object configured in a container (solnic)
- Booting is now handled by `System::Booter` object configured in a container (solnic)
- Importing containers is now handled by `System::Importer` object configured in a container (solnic)

[Compare v0.4.3...v0.5.0](https://github.com/dry-rb/dry-system/compare/v0.4.3...v0.5.0)

# 0.4.3 - 2016-08-01

### Fixed

- Return immediately from `Container.load_component` if the requested component key already exists in the container. This fixes a crash when requesting to load a manually registered component with a name that doesn't map to a filename (timriley in [#24](https://github.com/dry-rb/dry-system/pull/24))

[Compare v0.4.2...v0.4.3](https://github.com/dry-rb/dry-system/compare/v0.4.2...v0.4.3)

# 0.4.2 - 2016-07-26

### Fixed

- Ensure file components can be loaded when they're requested for the first time using their shorthand container identifier (i.e. with the container's default namespace removed) (timriley)

[Compare v0.4.1...v0.4.2](https://github.com/dry-rb/dry-system/compare/v0.4.1...v0.4.2)

# 0.4.1 - 2016-07-26 [YANKED]

### Fixed

- Require the 0.4.0 release of dry-auto_inject for the features below (in 0.4.0) to work properly (timriley)

[Compare v0.4.0...v0.4.1](https://github.com/dry-rb/dry-system/compare/v0.4.0...v0.4.1)

# 0.4.0 - 2016-07-26 [YANKED]

### Added

- Support for supplying a default namespace to a container, which is passed to the container's injector to allow for convenient shorthand access to registered objects in the same namespace (timriley in [#20](https://github.com/dry-rb/dry-system/pull/20))

    ```ruby
    # Set up container with default namespace
    module Admin
      class Container < Dry::Component::Container
        configure do |config|
          config.root = Pathname.new(__dir__).join("../..")
          config.default_namespace = "admin"
        end
      end

      Import = Container.injector
    end

    module Admin
      class CreateUser
        # "users.repository" will resolve an Admin::Users::Repository instance,
        # where previously you had to identify it as "admin.users.repository"
        include Admin::Import["users.repository"]
      end
    end
    ```

- Support for supplying to options directly to dry-auto_inject's `Builder` via `Dry::Component::Container#injector(options)`. This allows you to provide dry-auto_inject customizations like your own container of injection strategies (timriley in [#20](https://github.com/dry-rb/dry-system/pull/20))
- Support for accessing all available injector strategies, not just the defaults (e.g. `MyContainer.injector.some_custom_strategy`) (timriley in [#19](https://github.com/dry-rb/dry-system/pull/19))

### Changed

- Subclasses of `Dry::Component::Container` no longer have an `Injector` constant automatically defined within them. The recommended approach is to save your own injector object to a constant, which allows you to pass options to it at the same time, e.g. `MyApp::Import = MyApp::Container.injector(my_options)` (timriley in [#19](https://github.com/dry-rb/dry-system/pull/19))

[Compare v0.3.0...v0.4.0](https://github.com/dry-rb/dry-system/compare/v0.3.0...v0.4.0)

# 0.3.0 - 2016-06-18

### Changed

Removed two pieces that are moving to dry-web:

- Removed `env` setting from `Container` (timriley)
- Removed `Dry::Component::Config` and `options` setting from `Container` (timriley)
- Changed `Component#configure` behavior so it can be run multiple times for configuration to be applied in multiple passes (timriley)

[Compare v0.2.0...v0.3.0](https://github.com/dry-rb/dry-system/compare/v0.2.0...v0.3.0)

# 0.2.0 - 2016-06-13

### Changed

- Component core directory is now `component/` by default (timriley)
- Injector default stragegy is now whatever dry-auto_inject's default is (rather than hard-coding a particular default strategy for dry-system) (timriley)

### Fixed

- Fixed bug where specified auto-inject strategies were not respected (timriley)

[Compare v0.1.0...v0.2.0](https://github.com/dry-rb/dry-system/compare/v0.1.0...v0.2.0)

# 0.1.0 - 2016-06-07

### Added

* Provide a dependency injector as an `Inject` constant inside any subclass of `Dry::Component::Container`. This injector supports all of `dry-auto_inject`'s default injection strategies, and will lazily load any dependencies as they are injected. It also supports arbitrarily switching strategies, so they can be used in different classes as required (e.g. `include MyComponent::Inject.args["dep"]`) (timriley)
* Support aliased dependency names when calling the injector object (e.g. `MyComponent::Inject[foo: "my_app.foo", bar: "another.thing"]`) (timriley)
* Allow a custom dependency loader to be set on a container via its config (AMHOL)

    ```ruby
    class MyContainer < Dry::Component::Container
      configure do |config|
        # other config
        config.loader = MyLoader
      end
    end
    ```

### Changed

* `Container.boot` now only makes a simple `require` for the boot file (solnic)
* Container object is passed to `Container.finalize` blocks (solnic)
* Allow `Pathname` objects passed to `Container.require` (solnic)
* Support lazily loading missing dependencies from imported containers (solnic)
* `Container.import_module` renamed to `.injector` (timriley)
* Default injection strategy is now `kwargs`, courtesy of the new dry-auto_inject default (timriley)

[Compare v0.0.2...v0.1.0](https://github.com/dry-rb/dry-system/compare/v0.0.2...v0.1.0)

# 0.0.2 - 2015-12-24

### Added

* Containers have a `name` setting (solnic)
* Containers can be imported into one another (solnic)

### Changed

* Container name is used to determine the name of its config file (solnic)

[Compare v0.0.1...v0.0.2](https://github.com/dry-rb/dry-system/compare/v0.0.1...v0.0.2)

# 0.0.1 - 2015-12-24

First public release, extracted from rodakase project
