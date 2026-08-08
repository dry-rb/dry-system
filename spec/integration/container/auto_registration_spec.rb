# frozen_string_literal: true

require "dry/system/container"
require "zeitwerk"

RSpec.describe "Auto-registration" do
  specify "Resolving components from the container root" do
    root = make_tmp_directory

    with_directory(root) do
      write "root_component.rb", <<~RUBY
        module Test
          class RootComponent
          end
        end
      RUBY
    end

    container = Class.new(Dry::System::Container) do
      configure do |config|
        config.root = root
        config.component_dirs.add :root do |dir|
          dir.namespaces.add :root, const: "test"
        end
      end
    end

    expect(container["root_component"]).to be_a Test::RootComponent
  end

  specify "Resolving components from a non-finalized container, without a default namespace" do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/standard_container_without_default_namespace").realpath
          config.component_dirs.add "lib"
        end
      end

      Import = Container.injector
    end

    example_with_dep = Test::Container["test.example_with_dep"]

    expect(example_with_dep).to be_a Test::ExampleWithDep
    expect(example_with_dep.dep).to be_a Test::Dep
  end

  specify "Resolving components from a non-finalized container, with a default namespace" do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/standard_container_with_default_namespace").realpath
          config.component_dirs.add "lib" do |dir|
            dir.namespaces.add "test", key: nil
          end
        end
      end

      Import = Container.injector
    end

    example_with_dep = Test::Container["example_with_dep"]

    expect(example_with_dep).to be_a Test::ExampleWithDep
    expect(example_with_dep.dep).to be_a Test::Dep
  end
end
