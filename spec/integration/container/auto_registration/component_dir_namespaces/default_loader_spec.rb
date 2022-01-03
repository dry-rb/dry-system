# frozen_string_literal: true

RSpec.describe "Component dir namespaces / Default loader" do
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

  describe "constant namespaces" do
    context "top-level constant namespace" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add "ns", const: nil
        }
      }

      before :context do
        @dir = make_tmp_directory

        with_directory(@dir) do
          write "lib/ns/component.rb", <<~RUBY
            class Component
            end
          RUBY
        end
      end

      let(:cleanable_constants) { %i[Component] }

      context "lazy loading" do
        it "resolves the component as an instance of a top-level class" do
          expect(container["ns.component"]).to be_an_instance_of Component
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it "resolves the component as an instance of a top-level class" do
          expect(container["ns.component"]).to be_an_instance_of Component
        end
      end
    end

    context "distinct constant namespace" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add "ns", const: "my_namespace"
        }
      }

      before :context do
        @dir = make_tmp_directory

        with_directory(@dir) do
          write "lib/ns/component.rb", <<~RUBY
            module MyNamespace
              class Component
              end
            end
          RUBY

          write "lib/ns/nested/component.rb", <<~RUBY
            module MyNamespace
              module Nested
                class Component
                end
              end
            end
          RUBY
        end
      end

      let(:cleanable_modules) { super() + %i[MyNamespace] }

      context "lazy loading" do
        it "resolves the component as an instance of a class in the given constant namespace" do
          expect(container["ns.component"]).to be_an_instance_of MyNamespace::Component
          expect(container["ns.nested.component"]).to be_an_instance_of MyNamespace::Nested::Component
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it "resolves the component as an instance of a class in the given constant namespace" do
          expect(container["ns.component"]).to be_an_instance_of MyNamespace::Component
          expect(container["ns.nested.component"]).to be_an_instance_of MyNamespace::Nested::Component
        end
      end
    end

    context "distinct constant namespace for root" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add_root const: "my_namespace"
        }
      }

      before :context do
        @dir = make_tmp_directory

        with_directory(@dir) do
          write "lib/component.rb", <<~RUBY
            module MyNamespace
              class Component
              end
            end
          RUBY

          write "lib/nested/component.rb", <<~RUBY
            module MyNamespace
              module Nested
                class Component
                end
              end
            end
          RUBY
        end
      end

      let(:cleanable_modules) { super() + %i[MyNamespace] }

      context "lazy loading" do
        it "resolves the component as an instance of a class in the given constant namespace" do
          expect(container["component"]).to be_an_instance_of MyNamespace::Component
          expect(container["nested.component"]).to be_an_instance_of MyNamespace::Nested::Component
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it "resolves the component as an instance of a class in the given constant namespace" do
          expect(container["component"]).to be_an_instance_of MyNamespace::Component
          expect(container["nested.component"]).to be_an_instance_of MyNamespace::Nested::Component
        end
      end
    end
  end

  describe "key namespaces" do
    describe "top-level key namespace" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add "ns", key: nil
        }
      }

      before :context do
        @dir = make_tmp_directory

        with_directory(@dir) do
          write "lib/ns/component.rb", <<~RUBY
            module Ns
              class Component
              end
            end
          RUBY
        end
      end

      let(:cleanable_modules) { super() + %i[Ns] }

      context "lazy loading" do
        it "resolves the component via a top-level key" do
          expect(container["component"]).to be_an_instance_of Ns::Component
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it "resolves the component as an instance of a top-level class" do
          expect(container["component"]).to be_an_instance_of Ns::Component
        end
      end
    end

    describe "distinct key namespace" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add "ns", key: "my_ns"
        }
      }

      before :context do
        @dir = make_tmp_directory

        with_directory(@dir) do
          write "lib/ns/component.rb", <<~RUBY
            module Ns
              class Component
              end
            end
          RUBY

          write "lib/ns/nested/component.rb", <<~RUBY
            module Ns
              module Nested
                class Component
                end
              end
            end
          RUBY
        end
      end

      let(:cleanable_modules) { super() + %i[Ns] }

      context "lazy loading" do
        it "resolves the component via the given key namespace" do
          expect(container["my_ns.component"]).to be_an_instance_of Ns::Component
          expect(container["my_ns.nested.component"]).to be_an_instance_of Ns::Nested::Component
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it "resolves the component via the given key namespace" do
          expect(container["my_ns.component"]).to be_an_instance_of Ns::Component
          expect(container["my_ns.nested.component"]).to be_an_instance_of Ns::Nested::Component
        end
      end
    end

    describe "distinct key namespace for root" do
      let(:component_dir_config) {
        -> dir {
          dir.namespaces.add_root key: "my_ns"
        }
      }

      before :context do
        @dir = make_tmp_directory

        with_directory(@dir) do
          write "lib/component.rb", <<~RUBY
            class Component
            end
          RUBY

          write "lib/nested/component.rb", <<~RUBY
            module Nested
              class Component
              end
            end
          RUBY
        end
      end

      let(:cleanable_modules) { super() + %i[Nested] }
      let(:cleanable_constants) { %i[Component] }

      context "lazy loading" do
        it "resolves the component via the given key namespace" do
          expect(container["my_ns.component"]).to be_an_instance_of Component
          expect(container["my_ns.nested.component"]).to be_an_instance_of Nested::Component
        end
      end

      context "finalized" do
        before do
          container.finalize!
        end

        it "resolves the component via the given key namespace" do
          expect(container["my_ns.component"]).to be_an_instance_of Component
          expect(container["my_ns.nested.component"]).to be_an_instance_of Nested::Component
        end
      end
    end
  end

  describe "mixed constant and key namespaces" do
    let(:component_dir_config) {
      -> dir {
        dir.namespaces.add "ns", key: "my_ns", const: "my_namespace"
      }
    }

    before :context do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "lib/ns/component.rb", <<~RUBY
          module MyNamespace
            class Component
            end
          end
        RUBY

        write "lib/ns/nested/component.rb", <<~RUBY
          module MyNamespace
            module Nested
              class Component
              end
            end
          end
        RUBY
      end
    end

    let(:cleanable_modules) { super() + %i[MyNamespace] }

    context "lazy loading" do
      it "resolves the component via the given key namespace and returns an instance of a class in the given constant namespace" do
        expect(container["my_ns.component"]).to be_an_instance_of MyNamespace::Component
        expect(container["my_ns.nested.component"]).to be_an_instance_of MyNamespace::Nested::Component
      end
    end

    context "finalized" do
      before do
        container.finalize!
      end

      it "resolves the component via the given key namespace and returns an instance of a class in the given constant namespace" do
        expect(container["my_ns.component"]).to be_an_instance_of MyNamespace::Component
        expect(container["my_ns.nested.component"]).to be_an_instance_of MyNamespace::Nested::Component
      end
    end
  end
end
