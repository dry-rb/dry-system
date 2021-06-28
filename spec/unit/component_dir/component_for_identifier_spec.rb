# frozen_string_literal: true

require "dry/system/component_dir"
require "dry/system/config/component_dir"
require "dry/system/container"

RSpec.describe Dry::System::ComponentDir, "#component_for_identifier" do
  subject(:component) { component_dir.component_for_identifier(identifier) }

  let(:component_dir) {
    Dry::System::ComponentDir.new(
      config: Dry::System::Config::ComponentDir.new("component_dir_1") { |config|
        config.namespaces = ["namespace"]
        component_dir_options.each do |key, val|
          config.send :"#{key}=", val
        end
      },
      container: container
    )
  }
  let(:component_dir_options) { {} }
  let(:container) {
    container_root = root
    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = container_root
      end
    }
  }
  let(:root) { SPEC_ROOT.join("fixtures/unit/component").realpath }

  context "component file located" do
    let(:identifier) { "nested.component_file" }

    it "returns a component" do
      expect(component).to be_a Dry::System::Component
    end

    it "has a matching identifier" do
      expect(component.identifier.to_s).to eq identifier
    end

    it "has a file" do
      expect(component.file_exists?).to be true
    end

    it "has a matching file path" do
      expect(component.file_path.to_s).to eq root.join("component_dir_1/namespace/nested/component_file.rb").to_s
    end

    it "has the component dir's namespace" do
      expect(component.identifier.path_namespace).to eq "namespace"
    end

    context "options given as component dir config" do
      let(:component_dir_options) { {memoize: true} }

      it "has the component dir's options" do
        expect(component.memoize?).to be true
      end
    end

    context "options given as magic comments in file" do
      let(:identifier) { "nested.component_file_with_auto_register_false" }

      it "loads options specified within the file's magic comments" do
        expect(component.options).to include(auto_register: false)
      end
    end

    context "options given as both component dir config and as magic comments in file" do
      let(:component_dir_options) { {auto_register: true} }
      let(:identifier) { "nested.component_file_with_auto_register_false" }

      it "prefers the options specified as magic comments" do
        expect(component.options).to include(auto_register: false)
      end
    end
  end

  context "component file not located" do
    let(:identifier) { "nested.missing_component" }

    it "returns nil" do
      expect(component).to be_nil
    end
  end
end
