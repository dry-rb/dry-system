# frozen_string_literal: true

require "dry/system/component_dir"
require "dry/system/config/component_dir"
require "dry/system/container"

RSpec.describe Dry::System::ComponentDir, "#component_for_key" do
  subject(:component) { component_dir.component_for_key(key) }

  let(:component_dir) {
    Dry::System::ComponentDir.new(
      config: Dry::System::Config::ComponentDir.new("component_dir_1") { |config|
        config.namespaces.add "namespace", key: nil
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
    let(:key) { "nested.component_file" }

    it "returns a component" do
      expect(component).to be_a Dry::System::Component
    end

    it "has a matching key" do
      expect(component.key).to eq key
    end

    it "has the component dir's namespace" do
      expect(component.namespace.path).to eq "namespace"
    end

    context "options given as component dir config" do
      let(:component_dir_options) { {memoize: true} }

      it "has the component dir's options" do
        expect(component.memoize?).to be true
      end
    end

    context "options given as magic comments in file" do
      let(:key) { "nested.component_file_with_auto_register_false" }

      it "loads options specified within the file's magic comments" do
        expect(component.options).to include(auto_register: false)
      end
    end

    context "options given as both component dir config and as magic comments in file" do
      let(:component_dir_options) { {auto_register: true} }
      let(:key) { "nested.component_file_with_auto_register_false" }

      it "prefers the options specified as magic comments" do
        expect(component.options).to include(auto_register: false)
      end
    end
  end

  context "component file not located" do
    let(:key) { "nested.missing_component" }

    it "returns nil" do
      expect(component).to be_nil
    end
  end
end
