# frozen_string_literal: true

require "dry/system/component"
require "dry/system/identifier"
require "dry/system/loader"
require "dry/system/config/namespace"

RSpec.describe Dry::System::Component do
  subject(:component) {
    described_class.new(
      identifier,
      file_path: file_path,
      namespace: namespace,
      loader: loader
    )
  }

  let(:identifier) { Dry::System::Identifier.new("test.foo") }
  let(:file_path) { "/path/to/test/foo.rb" }
  let(:namespace) { Dry::System::Config::Namespace.default_root }
  let(:loader) { class_spy(Dry::System::Loader) }

  it "is loadable" do
    expect(component).to be_loadable
  end

  describe "#identifier" do
    it "is the given identifier" do
      expect(component.identifier).to be identifier
    end
  end

  describe "#key" do
    it "returns the identifier's key" do
      expect(component.key).to eq "test.foo"
    end
  end

  describe "#root_key" do
    it "returns the identifier's root_key" do
      expect(component.root_key).to eq :test
    end
  end

  describe "#instance" do
    it "builds and returns an instance via the loader" do
      loaded_instance = double(:instance)
      allow(loader).to receive(:call).with(component) { loaded_instance }

      expect(component.instance).to eql loaded_instance
    end

    it "forwards additional arguments to the loader" do
      loaded_instance = double(:instance)
      allow(loader).to receive(:call).with(component, "extra", "args") { loaded_instance }

      expect(component.instance("extra", "args")).to eql loaded_instance
    end
  end
end
