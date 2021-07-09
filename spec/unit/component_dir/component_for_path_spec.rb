# frozen_string_literal: true

require "dry/system/component_dir"
require "dry/system/config/component_dir"
require "dry/system/container"

RSpec.describe Dry::System::ComponentDir, "#component_for_path" do
  subject(:component) { component_dir.component_for_path(path) }

  let(:component_dir) {
    Dry::System::ComponentDir.new(
      config: Dry::System::Config::ComponentDir.new(component_dir_path) { |config|
        config.namespaces.add "namespace"
        component_dir_options.each do |key, val|
          config.send :"#{key}=", val
        end
      },
      container: container
    )
  }
  let(:component_dir_path) { "component_dir_1" }
  # let(:namespaces) { ["namespace"] }
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

  context "component file exists within default namespace" do
    let(:path) { root.join(component_dir_path, "namespace", "nested/component_file.rb") }

    it "returns a component" do
      expect(component).to be_a Dry::System::Component
    end

    it "has a matching identifier" do
      expect(component.identifier.to_s).to eq "nested.component_file"
    end

    it "has a file" do
      expect(component.file_exists?).to be true
    end

    it "has a matching file path" do
      expect(component.file_path.to_s).to eq path.to_s
    end

    it "has the component dir's namespace" do
      # FIXME: not sure if I really want base_path for this
      expect(component.identifier.base_path).to eq "namespace"
    end

    context "options given as component dir config" do
      let(:component_dir_options) { {memoize: true} }

      it "has the component dir's options" do
        expect(component.memoize?).to be true
      end
    end

    context "options given as magic comments in file" do
      let(:path) { root.join(component_dir_path, "namespace", "nested/component_file_with_auto_register_false.rb") }

      it "loads options specified within the file's magic comments" do
        expect(component.options).to include(auto_register: false)
      end
    end

    context "options given as both component dir config and as magic comments in file" do
      let(:component_dir_options) { {auto_register: true} }
      let(:path) { root.join(component_dir_path, "namespace", "nested/component_file_with_auto_register_false.rb") }

      it "prefers the options specified as magic comments" do
        expect(component.options).to include(auto_register: false)
      end
    end
  end

  context "component file exists outside of default namespace" do
    let(:path) { root.join(component_dir_path, "outside_namespace/component_file.rb") }

    it "returns a component" do
      expect(component).to be_a Dry::System::Component
    end

    it "has a matching identifier, without the namespace" do
      expect(component.identifier.to_s).to eq "outside_namespace.component_file"
    end

    it "has a file" do
      expect(component.file_exists?).to be true
    end

    it "has a matching file path" do
      expect(component.file_path.to_s).to eq path.to_s
    end

    it "does not have the component dir's namespace" do
      expect(component.identifier.path_namespace).to be_nil
    end
  end

  context "component file does not exist" do
    let(:path) { "/missing/component/file.rb" }

    it "raises an error" do
      # To avoid an extra filesystem check for an internal method that's only called with
      # known-existing files, we don't explicitly check for file existence. Instead, this
      # example exists to ensure that _some_ error is raised when the file is non-existent
      # (In this case, it's the error raised from the MagicCommentsParser attempting to
      # read the file)
      expect { component }.to raise_error Errno::ENOENT
    end
  end
end
