# frozen_string_literal: true

require "dry/system/loader/autoloading"
require "zeitwerk"

RSpec.describe "Component dir namespaces / Autoloading loader" do
  let(:container) {
    root = @dir
    dir_config = defined?(component_dir_config) ? component_dir_config : -> * {}

    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = root
        config.component_dirs.add "lib" do |dir|
          dir.loader = Dry::System::Loader::Autoloading
          dir_config.(dir)
        end
      end
    }
  }

  let(:loader) { Zeitwerk::Loader.new }

  after do
    Zeitwerk::Registry.loaders.each(&:unload)

    Zeitwerk::Registry.loaders.clear
    Zeitwerk::Registry.loaders_managing_gems.clear

    Zeitwerk::ExplicitNamespace.cpaths.clear
    Zeitwerk::ExplicitNamespace.tracer.disable
  end

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

        write "lib/ns/nested/component.rb", <<~RUBY
          module Nested
            class Component
            end
          end
        RUBY
      end
    end

    before do
      loader.push_dir @dir.join("lib/ns").realpath
      loader.setup
    end

    let(:cleanable_constants) { %i[Component] }

    context "lazy loading" do
      it "resolves the component as an instance of a top-level class" do
        expect(container["ns.component"]).to be_an_instance_of Component
        expect(container["ns.nested.component"]).to be_an_instance_of Nested::Component
      end
    end

    context "finalized" do
      before do
        container.finalize!
      end

      it "resolves the component as an instance of a top-level class" do
        expect(container["ns.component"]).to be_an_instance_of Component
        expect(container["ns.nested.component"]).to be_an_instance_of Nested::Component
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

    before do
      module MyNamespace; end

      loader.push_dir @dir.join("lib", "ns").realpath, namespace: MyNamespace
      loader.setup
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
        dir.namespaces.root const: "my_namespace"
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

    before do
      module MyNamespace; end

      loader.push_dir @dir.join("lib").realpath, namespace: MyNamespace
      loader.setup
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
