# frozen_string_literal: true

RSpec.describe "Component dir namespaces / Multiple namespaces" do
  let(:cleanable_constants) { %i[Component RootComponent] }
  let(:cleanable_modules) { %i[Admin Test] }

  let(:container) {
    root = @dir
    dir_config = defined?(component_dir_config) ? component_dir_config : -> * {}

    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = root
        config.component_dirs.add("lib", &dir_config)
      end
    }
  }

  context "single configured path namespace" do
    let(:component_dir_config) {
      -> dir {
        dir.namespaces.add "test", key: nil
      }
    }

    before :context do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "lib/test/component.rb", <<~RUBY
          module Test
            class Component
            end
          end
        RUBY
      end
    end

    context "lazy loading" do
      it "resolves the compoment via the namespace" do
        expect(container["component"]).to be_an_instance_of Test::Component
      end
    end

    context "finalized" do
      before do
        container.finalize!
      end

      it "resolves the compoment via the namespace" do
        expect(container["component"]).to be_an_instance_of Test::Component
      end
    end
  end

  context "mixed path and root namespace" do
    before :context do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "lib/test/component.rb", <<~RUBY
          module Test
            class Component
            end
          end
        RUBY

        write "lib/component.rb", <<~RUBY
          class Component
          end
        RUBY

        write "lib/root_component.rb", <<~RUBY
          class RootComponent
          end
        RUBY
      end
    end

    context "configured path namespace before implicit trailing root namespace" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add "test", key: nil
        }
      }

      context "lazy loading" do
        it "prefers the configured namespace when resolving components" do
          expect(container["component"]).to be_an_instance_of Test::Component
          expect(container["root_component"]).to be_an_instance_of RootComponent
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it "prefers the configured namespace when resolving components" do
          expect(container["component"]).to be_an_instance_of Test::Component
          expect(container["root_component"]).to be_an_instance_of RootComponent
        end
      end
    end

    context "leading root namespace before configured path namespace" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add_root
          dir.namespaces.add "test", key: nil
        }
      }

      context "lazy loading" do
        it "prefers the root namespace when resolving components" do
          expect(container["component"]).to be_an_instance_of Component
          expect(container["root_component"]).to be_an_instance_of RootComponent
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it "prefers the root namespace when resolving components" do
          expect(container["component"]).to be_an_instance_of Component
          expect(container["root_component"]).to be_an_instance_of RootComponent
        end
      end
    end
  end

  context "multiple configured path namespaces" do
    before :context do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "lib/admin/admin_component.rb", <<~RUBY
          module Admin
            class AdminComponent
            end
          end
        RUBY

        write "lib/admin/component.rb", <<~RUBY
          module Admin
            class Component
            end
          end
        RUBY

        write "lib/test/test_component.rb", <<~RUBY
          module Test
            class TestComponent
            end
          end
        RUBY

        write "lib/test/component.rb", <<~RUBY
          module Test
            class Component
            end
          end
        RUBY

        write "lib/component.rb", <<~RUBY
          class Component
          end
        RUBY

        write "lib/root_component.rb", <<~RUBY
          class RootComponent
          end
        RUBY
      end
    end

    context "ordered one way" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add "admin", key: nil
          dir.namespaces.add "test", key: nil
        }
      }

      context "lazy loading" do
        it "prefers the earlier configured namespaces when resolving components" do
          expect(container["component"]).to be_an_instance_of Admin::Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it "prefers the earlier configured namespaces when resolving components" do
          expect(container["component"]).to be_an_instance_of Admin::Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
        end
      end
    end

    context "ordered the other way" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add "test", key: nil
          dir.namespaces.add "admin", key: nil
        }
      }

      context "lazy loading" do
        it "prefers the earlier configured namespaces when resolving components" do
          expect(container["component"]).to be_an_instance_of Test::Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it "prefers the earlier configured namespaces when resolving components" do
          expect(container["component"]).to be_an_instance_of Test::Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
        end
      end
    end

    context "leading root namespace" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add_root
          dir.namespaces.add "admin", key: nil
          dir.namespaces.add "test", key: nil
        }
      }

      context "lazy loading" do
        it "prefers the earlier configured namespaces when resolving components" do
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

        it "prefers the earlier configured namespaces when resolving components" do
          expect(container["component"]).to be_an_instance_of Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
          expect(container["root_component"]).to be_an_instance_of RootComponent
        end
      end
    end

    context "root namespace between path namespaces" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add "admin", key: nil
          dir.namespaces.add_root
          dir.namespaces.add "test", key: nil
        }
      }

      context "lazy loading" do
        it "prefers the earlier configured namespaces when resolving components" do
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

        it "prefers the earlier configured namespaces when resolving components" do
          expect(container["component"]).to be_an_instance_of Admin::Component
          expect(container["admin_component"]).to be_an_instance_of Admin::AdminComponent
          expect(container["test_component"]).to be_an_instance_of Test::TestComponent
          expect(container["root_component"]).to be_an_instance_of RootComponent
        end
      end
    end
  end
end
