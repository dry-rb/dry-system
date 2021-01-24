# frozen_string_literal: true

require "dry/system/component"

require "dry/system/component_dir"
require "dry/system/config/component_dir"
require "dry/system/container"
require "dry/system/loader"

RSpec.describe Dry::System::Component, ".new_from_component_dir" do
  subject(:component) {
    described_class.new_from_component_dir(
      identifier,
      component_dir,
      file_path,
      options,
    )
  }

  let(:identifier) { "nested.component_file" }
  let(:file_path) { root.join("component_dir_1/namespace/nested/component_file.rb") }

  let(:component_dir) {
    Dry::System::ComponentDir.new(
      config: Dry::System::Config::ComponentDir.new("component_dir_1") { |config|
        config.default_namespace = "namespace"
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
  let(:options) { {} }

  it "returns a component" do
    expect(component).to be_a Dry::System::Component
  end

  it "has a file" do
    expect(component.file_exists?).to be true
  end

  it "has the provided file path" do
    expect(component.file_path).to be file_path
  end

  it "keeps the component dir's namespace" do
    expect(component.namespace).to eq "namespace"
  end

  describe "component options" do
    let(:options) { {arg_option: true} }

    context "no options in component dir or magic comments" do
      it "includes the options given as args" do
        expect(component.options).to include options
      end
    end

    context "options given as component dir config" do
      let(:options) { {auto_register: true} }
      let(:component_dir_options) { {auto_register: false} }

      it "prefers the component dir options over the options given as args" do
        expect(component.options).to include(auto_register: false)
      end
    end

    context "options given as magic comments in file" do
      let(:options) { {auto_register: true} }
      let(:component_dir_options) { {auto_register: false} }

      let(:identifier) { "nested.component_file_with_auto_register_true" }
      let(:file_path) { root.join("component_dir_1/namespace/nested/component_file_with_auto_register_true.rb") }

      it "prefers the magic comment options over the options given as component dir config" do
        expect(component.options).to include(auto_register: true)
      end
    end
  end
end
