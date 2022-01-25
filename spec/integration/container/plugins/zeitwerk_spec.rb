# frozen_string_literal: true

require "dry/system/container"

RSpec.describe "Zeitwerk plugin" do
  include ZeitwerkHelpers

  after { teardown_zeitwerk }

  specify "Resolving components using Zeitwerk" do
    app = Class.new(Dry::System::Container) do
      use :zeitwerk

      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/zeitwerk").realpath

        config.component_dirs.add "lib" do |dir|
          dir.namespaces.add "test", key: nil
        end
      end
    end

    foo = app["foo"]
    entity = foo.call

    expect(foo).to be_a Test::Foo
    expect(entity).to be_a Test::Entities::FooEntity
  end

  specify "Eager loads after finalization" do
    app = Class.new(Dry::System::Container) do
      use :zeitwerk, eager_load: true

      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/zeitwerk_eager").realpath

        config.component_dirs.add "lib"
      end
    end

    expect { app.finalize! }
      .to change { global_variables }
      .to(a_collection_including(:$zeitwerk_eager_loaded))
  end

  specify "Eager loads in production by default" do
    app = Class.new(Dry::System::Container) do
      use :env, inferrer: -> { :production }
      use :zeitwerk

      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/zeitwerk_eager_load_production").realpath

        config.component_dirs.add "lib"
      end
    end

    expect { $zeitwerk_eager_load_production_loaded }
      .to output(/\$zeitwerk_eager_load_production_loaded' not initialized/)
      .to_stderr

    app.finalize!

    expect($zeitwerk_eager_load_production_loaded).to be(true)
  end
end
