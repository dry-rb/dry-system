# frozen_string_literal: true

require "dry/system/component"

require "dry/system/component_dir"
require "dry/system/config/component_dir"
require "dry/system/container"
require "dry/system/loader"

RSpec.describe Dry::System::Component, ".locate" do
  subject(:component) { Dry::System::Component.locate(identifier, component_dirs, **options) }

  let(:component_dirs) {
    component_dir_paths.map { |dir_path|
      Dry::System::ComponentDir.new(
        config: Dry::System::Config::ComponentDir.new(dir_path) { |config|
          config.default_namespace = "namespace"
        },
        container: container
      )
    }
  }
  let(:component_dir_paths) { %w[component_dir_1 component_dir_2] }
  let(:container) {
    container_root = root
    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = container_root
      end
    }
  }

  let(:root) { SPEC_ROOT.join("fixtures/unit/component").realpath }
  let(:options) { {} }

  context "component file located" do
    let(:identifier) { "nested.component_file" }

    it "returns a component" do
      expect(component).to be_a Dry::System::Component
    end

    it "has a file" do
      expect(component.file_exists?).to be true
    end

    it "matches the first component file found within the given component dirs" do
      expect(component.file_path.to_s).to eq root.join("component_dir_1/namespace/nested/component_file.rb").to_s
    end

    context "component dir paths given in another order" do
      let(:component_dir_paths) { %w[component_dir_2 component_dir_1] }

      it "matches the first component file found within the dirs in the given order" do
        expect(component.file_path.to_s).to eq root.join("component_dir_2/namespace/nested/component_file.rb").to_s
      end
    end

    it "loads the component dir's namespace" do
      expect(component.namespace).to eq "namespace"
    end

    context "file contains options as magic comments" do
      let(:identifier) { "nested.component_file_with_auto_register_false" }

      it "loads any options specified within the file's magic comments" do
        expect(component.options).to include(auto_register: false)
      end
    end
  end

  context "component file not located" do
    let(:identifier) { "nested.missing" }

    it "returns a component" do
      expect(component).to be_a Dry::System::Component
    end

    it "does not have a file" do
      expect(component.file_exists?).to be false
    end

    it "does not have a file_path" do
      expect(component.file_path).to be nil
    end

    it "does not have a namespace" do
      expect(component.namespace).to be nil
    end

    it "does not have additional file-provided options" do
      expect(component.options).not_to include :auto_register
    end
  end
end
