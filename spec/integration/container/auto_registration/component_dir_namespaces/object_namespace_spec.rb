require "dry/system/loader/autoloading"
require "zeitwerk"

RSpec.describe "Component dir object namespace" do
  context "default loader" do
    let!(:container) {
      module Test
        class Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/mixed_path_and_object_namespace").realpath

            config.component_dirs.add "lib" do |dir|
              # no path namespace (i.e. a "flattened" folder structure), but an object namespace of "Test"
              dir.namespaces = [[nil, "test"]]
            end
          end
        end
      end

      Test::Container
    }

    context "lazy loading" do
      specify "yep" do
        expect(container["component"]).to be_an_instance_of Test::Component
      end
    end

    context "finalized" do
      before do
        container.finalize!
      end

      specify "yep?" do
        expect(container["component"]).to be_an_instance_of Test::Component
      end
    end
  end

  context "autoloading loader" do
    let!(:container) {
      module Test
        class Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures/component_dir_namespaces/mixed_path_and_object_namespace").realpath

            config.component_dirs.add "lib" do |dir|
              # no path namespace (i.e. a "flattened" folder structure), but an object namespace of "Test"
              dir.namespaces = [[nil, "test"]]
              dir.loader = Dry::System::Loader::Autoloading
            end
          end
        end
      end

      Test::Container
    }

    before do
      loader = Zeitwerk::Loader.new
      loader.push_dir Test::Container.config.root.join("lib").realpath, namespace: Test
      loader.setup
    end

    after do
      Zeitwerk::Registry.loaders.each(&:unload)

      Zeitwerk::Registry.loaders.clear
      Zeitwerk::Registry.loaders_managing_gems.clear

      Zeitwerk::ExplicitNamespace.cpaths.clear
      Zeitwerk::ExplicitNamespace.tracer.disable
    end

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
end
