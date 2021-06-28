# frozen_string_literal: true

require "dry/system/component_dir"

require "dry/system/container"
require "dry/system/config/component_dir"

RSpec.describe Dry::System::ComponentDir do
  subject(:component_dir) { described_class.new(config: config, container: container) }

  let(:config) { Dry::System::Config::ComponentDir.new(dir_path) }
  let(:dir_path) { "component_dir" }
  let(:container) {
    container_root = root

    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = container_root
      end
    }
  }
  let(:root) { SPEC_ROOT.join("fixtures/unit").realpath }

  describe "config" do
    it "delegates config methods to the config" do
      expect(component_dir.path).to eql config.path
      expect(component_dir.auto_register).to eql config.auto_register
      expect(component_dir.add_to_load_path).to eql config.add_to_load_path
    end

    # TODO
    xit "provides a default root namespace if none is specified"
  end

  describe "#full_path" do
    it "is a pathname" do
      expect(component_dir.full_path).to be_a_kind_of Pathname
    end

    it "returns the config's path appended onto the container's root" do
      expect(component_dir.full_path.to_s).to eq "#{root}/#{dir_path}"
    end
  end
end
