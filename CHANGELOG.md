# 0.1.0 - 2016-06-07

## Added

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

## Changed

* `Container.boot` now only makes a simple `require` for the boot file (solnic)
* Container object is passed to `Container.finalize` blocks (solnic)
* Allow `Pathname` objects passed to `Container.require` (solnic)
* Support lazily loading missing dependencies from imported containers (solnic)
* `Container.import_module` renamed to `.injector` (timriley)
* Default injection strategy is now `kwargs`, courtesy of the new dry-auto_inject default (timriley)

# 0.0.2 - 2015-12-24

## Added

* Containers have a `name` setting (solnic)
* Containers can be imported into one another (solnic)

## Changed

* Container name is used to determine the name of its config file (solnic)

# 0.0.1 - 2015-12-24

First public release, extracted from rodakase project
