require "dry/system/component_dir"
require "dry/system/config/component_dir"

RSpec.describe Dry::System::ComponentDir do
  subject(:component_dir) { described_class.new(config: config, root: root) }
  let(:config) { Dry::System::Config::ComponentDir.new(dir_path) }
  let(:dir_path) { "component_dir" }
  let(:root) { SPEC_ROOT.join("fixtures/unit").realpath }

  describe "config" do
    it "delegates config methods to the config" do
      expect(component_dir.path).to eql config.path
      expect(component_dir.auto_register).to eql config.auto_register
      expect(component_dir.add_to_load_path).to eql config.add_to_load_path
      expect(component_dir.default_namespace).to eql config.default_namespace
    end
  end

  describe "#full_path" do
    it "is a pathname" do
      expect(component_dir.root).to be_a_kind_of Pathname
    end

    it "returns the config's path appended onto the root" do
      expect(component_dir.full_path.to_s).to eq "#{root}/#{dir_path}"
    end
  end

  describe "#component_file" do
    context "component file exists matching the given path" do
      it "returns the full path to the file" do
        expect(component_dir.component_file("component_file").to_s).to eq "#{root}/#{dir_path}/component_file.rb"
      end

      it "returns a pathname" do
        expect(component_dir.component_file("component_file")).to be_a_kind_of Pathname
      end
    end

    context "component file matching the given path does not exist" do
      it "returns nil" do
        expect(component_dir.component_file("missing")).to be_nil
      end
    end
  end
end
