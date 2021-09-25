# frozen_string_literal: true

RSpec.describe "Component dir path namespaces" do
  context "single namespace" do
    let!(:container) {
      module Test
        class Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/single_namespace").realpath

            config.component_dirs.add "lib" do |dir|
              dir.namespaces.add "test", identifier: nil
            end
          end
        end
      end

      Test::Container
    }

    context "lazy loading" do
      it do
        expect(container["component"]).to be_an_instance_of Test::Component
      end
    end

    context "finalized" do
      before do
        container.finalize!
      end

      it do
        expect(container["component"]).to be_an_instance_of Test::Component
      end
    end
  end

  context "single named namespace and nil namespace" do
    let!(:container) {
      module Test
        class Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/single_and_null_namespace").realpath

            config.component_dirs.add "lib" do |dir|
              dir.namespaces.add "test", identifier: nil
            end
          end
        end
      end

      Test::Container
    }

    context "lazy loading" do
      it do
        expect(container["component"]).to be_an_instance_of Test::Component
        expect(container["root_component"]).to be_an_instance_of RootComponent
      end
    end

    context "finalized" do
      before do
        container.finalize!
      end

      it do
        expect(container["component"]).to be_an_instance_of Test::Component
        expect(container["root_component"]).to be_an_instance_of RootComponent
      end
    end

    # FIXME: how do I clean up the root namespace? look for the other place I've done it
  end

  context "nil namespace then single named namespace" do
    let!(:container) {
      module Test
        class Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/single_and_null_namespace").realpath

            config.component_dirs.add "lib" do |dir|
              dir.namespaces.root
              dir.namespaces.add "test", identifier: nil
            end
          end
        end
      end

      Test::Container
    }

    context "lazy loading" do
      it do
        expect(container["component"]).to be_an_instance_of Component
        expect(container["root_component"]).to be_an_instance_of RootComponent
      end
    end

    context "finalized" do
      before do
        container.finalize!
      end

      it do
        expect(container["component"]).to be_an_instance_of Component
        expect(container["root_component"]).to be_an_instance_of RootComponent
      end
    end

    # FIXME: how do I clean up the root namespace? look for the other place I've done it
  end

  context "two named namespaces" do
    context "ordered one way" do
      let!(:container) {
        module Test
          class Container < Dry::System::Container
            configure do |config|
              config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/two_namespaces").realpath

              config.component_dirs.add "lib" do |dir|
                dir.namespaces.add "admin", identifier: nil
                dir.namespaces.add "test", identifier: nil
              end
            end
          end
        end

        Test::Container
      }

      context "lazy loading" do
        it do
          expect(container["component"]).to be_an_instance_of Admin::Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it do
          expect(container["component"]).to be_an_instance_of Admin::Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
        end
      end
    end

    context "ordered the other way" do
      let!(:container) {
        module Test
          class Container < Dry::System::Container
            configure do |config|
              config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/two_namespaces").realpath

              config.component_dirs.add "lib" do |dir|
                dir.namespaces.add "test", identifier: nil
                dir.namespaces.add "admin", identifier: nil
              end
            end
          end
        end

        Test::Container
      }

      context "lazy loading" do
        it do
          expect(container["component"]).to be_an_instance_of Test::Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it do
          expect(container["component"]).to be_an_instance_of Test::Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
        end
      end
    end
  end

  context "two named namespaces and nil namespace" do
    context "order 1" do
      let!(:container) {
        module Test
          class Container < Dry::System::Container
            configure do |config|
              config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/two_namespaces").realpath

              config.component_dirs.add "lib" do |dir|
                dir.namespaces.root
                dir.namespaces.add "admin", identifier: nil
                dir.namespaces.add "test", identifier: nil
              end
            end
          end
        end

        Test::Container
      }

      context "lazy loading" do
        it do
          expect(container["component"]).to be_an_instance_of Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
          expect(container["root_component"]).to be_an_instance_of RootComponent
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it do
          expect(container["component"]).to be_an_instance_of Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
          expect(container["root_component"]).to be_an_instance_of RootComponent
        end
      end
    end

    context "order 2" do
      let!(:container) {
        module Test
          class Container < Dry::System::Container
            configure do |config|
              config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/two_namespaces").realpath

              config.component_dirs.add "lib" do |dir|
                dir.namespaces.add "admin", identifier: nil
                dir.namespaces.root
                dir.namespaces.add "test", identifier: nil
              end
            end
          end
        end

        Test::Container
      }

      context "lazy loading" do
        it do
          expect(container["component"]).to be_an_instance_of Admin::Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
          expect(container["root_component"]).to be_an_instance_of RootComponent
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it do
          expect(container["component"]).to be_an_instance_of Admin::Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
          expect(container["root_component"]).to be_an_instance_of RootComponent
        end
      end
    end
  end
end
