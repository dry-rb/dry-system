# frozen_string_literal: true

RSpec.describe "Plugins / Injector mixin" do
  describe "default options" do
    it "creates a 'Deps' mixin in the container's parent module" do
      module Test
        class Container < Dry::System::Container
          use :injector_mixin
          configured!
        end
      end

      component = Object.new
      Test::Container.register "component", component

      depending_obj = Class.new do
        include Test::Deps["component"]
      end.new

      expect(depending_obj.component).to be component
    end
  end

  describe "name given" do
    it "creates a mixin with the given name in the container's parent module" do
      module Test
        class Container < Dry::System::Container
          use :injector_mixin, name: "Inject"
          configured!
        end
      end

      component = Object.new
      Test::Container.register "component", component

      depending_obj = Class.new do
        include Test::Inject["component"]
      end.new

      expect(depending_obj.component).to be component
    end
  end

  describe "nested name given" do
    it "creates a mixin with the given name in the container's parent module" do
      module Test
        class Container < Dry::System::Container
          use :injector_mixin, name: "Inject::These::Pls"
          configured!
        end
      end

      component = Object.new
      Test::Container.register "component", component

      depending_obj = Class.new do
        include Test::Inject::These::Pls["component"]
      end.new

      expect(depending_obj.component).to be component
    end
  end

  describe "top-level name given" do
    it "creates a mixin with the given name in the top-level module" do
      module Test
        class Container < Dry::System::Container
          use :injector_mixin, name: "::Deps"
          configured!
        end
      end

      component = Object.new
      Test::Container.register "component", component

      depending_obj = Class.new do
        include ::Deps["component"]
      end.new

      expect(depending_obj.component).to be component
    end
  end
end
