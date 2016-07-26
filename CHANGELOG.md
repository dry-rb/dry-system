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
