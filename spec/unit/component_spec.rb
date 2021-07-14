# frozen_string_literal: true

require "dry/system/component"
require "dry/system/identifier"
require "dry/system/loader"

RSpec.describe Dry::System::Component do
  subject(:component) { Dry::System::Component.new(identifier, file_path: file_path, loader: loader) }

  let(:identifier) { "test.foo" }
  let(:file_path) { nil }
  let(:loader) { Dry::System::Loader }

  describe "#identifier" do
    context "component initialized with identifier" do
      it "returns an identifier for the given identifier string" do
        expect(component.identifier).to be_an_instance_of Dry::System::Identifier
        expect(component.identifier.to_s).to eq "test.foo"
      end
    end

    context "component initialized with Identifier instance" do
      let(:identifier) { Dry::System::Identifier.new("test.foo", separator: ".") }

      it "returns the given identifier instance" do
        expect(component.identifier).to be identifier
      end
    end
  end

  describe "#key" do
    it "returns the given identifier string" do
      expect(component.key).to eq "test.foo"
    end
  end

  describe "#path" do
    it "returns a path based on the identifier" do
      expect(component.path).to eq "test/foo"
    end
  end

  describe "#root_key" do
    it "returns the identifier's root_key" do
      expect(component.root_key).to eql component.identifier.root_key
    end
  end

  describe "#file_exists?" do
    context "file_path given" do
      let(:file_path) { "/full/path/to/test/foo.rb" }

      it "returns true" do
        expect(component.file_exists?).to be true
      end
    end

    context "no file_path given" do
      let(:file_path) { nil }

      it "returns false" do
        expect(component.file_exists?).to be false
      end
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
