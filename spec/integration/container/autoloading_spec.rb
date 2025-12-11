# frozen_string_literal: true

require "dry/system/container"
require "dry/system/loader/autoloading"
require "zeitwerk"

RSpec.describe "Autoloading loader" do
  specify "Resolving components using Zeitwerk" do
    module Test
      class Container < Dry::System::Container
        config.root = SPEC_ROOT.join("fixtures/autoloading").realpath
        config.component_dirs.loader = Dry::System::Loader::Autoloading
        config.component_dirs.add "lib" do |dir|
          dir.add_to_load_path = false
          dir.namespaces.add "test", key: nil
        end
      end
    end

    loader = ZeitwerkLoaderRegistry.new_loader
    loader.push_dir Test::Container.config.root.join("lib").realpath
    loader.setup

    foo = Test::Container["foo"]
    entity = foo.call

    expect(foo).to be_a Test::Foo
    expect(entity).to be_a Test::Entities::FooEntity

    ZeitwerkLoaderRegistry.clear
  end
end
