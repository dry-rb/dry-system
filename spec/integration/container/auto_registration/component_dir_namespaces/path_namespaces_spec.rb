RSpec.describe "Component dir path namespaces" do
  specify "single namespace" do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/single_namespace").realpath

          config.component_dirs.add "lib" do |dir|
            dir.namespaces = ["test"]
          end
        end
      end
    end

    expect(Test::Container["component"]).to be_an_instance_of Test::Component
  end

  specify "single named namespace and nil namespace" do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/single_and_null_namespace").realpath

          config.component_dirs.add "lib" do |dir|
            dir.namespaces = ["test", nil]
          end
        end
      end
    end

    expect(Test::Container["component"]).to be_an_instance_of Test::Component
    expect(Test::Container["root_component"]).to be_an_instance_of RootComponent

    # FIXME: how do I clean up the root namespace? look for the other place I've done it
  end

  specify "nil namespace then single named namespace" do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/single_and_null_namespace").realpath

          config.component_dirs.add "lib" do |dir|
            dir.namespaces = [nil, "test"]
          end
        end
      end
    end

    expect(Test::Container["component"]).to be_an_instance_of Component
    expect(Test::Container["root_component"]).to be_an_instance_of RootComponent

    # FIXME: how do I clean up the root namespace? look for the other place I've done it
  end

  context "two named namespaces" do
    specify "ordered one way" do
      module Test
        class Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/two_namespaces").realpath

            config.component_dirs.add "lib" do |dir|
              dir.namespaces = ["admin", "test"]
            end
          end
        end
      end

      expect(Test::Container["component"]).to be_an_instance_of Admin::Component
      expect(Test::Container["admin_component"]).to be_an_instance_of Admin::AdminComponent
      expect(Test::Container["test_component"]).to be_an_instance_of Test::TestComponent
    end

    specify "ordered the other way" do
      module Test
        class Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/two_namespaces").realpath

            config.component_dirs.add "lib" do |dir|
              dir.namespaces = ["test", "admin"]
            end
          end
        end
      end

      expect(Test::Container["component"]).to be_an_instance_of Test::Component
      expect(Test::Container["admin_component"]).to be_an_instance_of Admin::AdminComponent
      expect(Test::Container["test_component"]).to be_an_instance_of Test::TestComponent
    end
  end
end
