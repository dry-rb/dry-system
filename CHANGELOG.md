# 0.4.1 - 2016-07-26

### Fixed

- Require the 0.4.0 release of dry-auto_inject for the features below (in 0.4.0) to work properly (timriley)

[Compare v0.3.0...v0.4.0](https://github.com/dry-rb/dry-component/compare/v0.4.0...v0.4.1)

# 0.4.0 - 2016-07-26

### Added

- Support for supplying a default namespace to a container, which is passed to the container's injector to allow for convenient shorthand access to registered objects in the same namespace (timriley in [#20](https://github.com/dry-rb/dry-component/pull/20))

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

- Support for supplying to options directly to dry-auto_inject's `Builder` via `Dry::Component::Container#injector(options)`. This allows you to provide dry-auto_inject customizations like your own container of injection strategies (timriley in [#20](https://github.com/dry-rb/dry-component/pull/20))
- Support for accessing all available injector strategies, not just the defaults (e.g. `MyContainer.injector.some_custom_strategy`) (timriley in [#19](https://github.com/dry-rb/dry-component/pull/19))

### Changed

- Subclasses of `Dry::Component::Container` no longer have an `Injector` constant automatically defined within them. The recommended approach is to save your own injector object to a constant, which allows you to pass options to it at the same time, e.g. `MyApp::Import = MyApp::Container.injector(my_options)` (timriley in [#19](https://github.com/dry-rb/dry-component/pull/19))

[Compare v0.3.0...v0.4.0](https://github.com/dry-rb/dry-component/compare/v0.3.0...v0.4.0)

# 0.3.0 - 2016-06-18

### Changed

Removed two pieces that are moving to dry-web:

- Removed `env` setting from `Container` (timriley)
- Removed `Dry::Component::Config` and `options` setting from `Container` (timriley)
- Changed `Component#configure` behavior so it can be run multiple times for configuration to be applied in multiple passes (timriley)

[Compare v0.2.0...v0.3.0](https://github.com/dry-rb/dry-component/compare/v0.2.0...v0.3.0)

# 0.2.0 - 2016-06-13

### Changed

- Component core directory is now `component/` by default (timriley)
- Injector default stragegy is now whatever dry-auto_inject's default is (rather than hard-coding a particular default strategy for dry-component) (timriley)

### Fixed

- Fixed bug where specified auto-inject strategies were not respected (timriley)

[Compare v0.1.0...v0.2.0](https://github.com/dry-rb/dry-component/compare/v0.1.0...v0.2.0)

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

[Compare v0.0.2...v0.1.0](https://github.com/dry-rb/dry-component/compare/v0.0.2...v0.1.0)

# 0.0.2 - 2015-12-24

### Added

* Containers have a `name` setting (solnic)
* Containers can be imported into one another (solnic)

### Changed

* Container name is used to determine the name of its config file (solnic)

[Compare v0.0.1...v0.0.2](https://github.com/dry-rb/dry-component/compare/v0.0.1...v0.0.2)

# 0.0.1 - 2015-12-24

First public release, extracted from rodakase project
