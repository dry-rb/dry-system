# frozen_string_literal: true

require "dry/system/identifier"
require "dry/system/indirect_component"

RSpec.describe Dry::System::IndirectComponent do
  subject(:component) { described_class.new(identifier) }
  let(:identifier) { Dry::System::Identifier.new("test.foo") }

  it "is not loadable" do
    expect(component).not_to be_loadable
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
    it "returns the identifier's root key" do
      expect(component.root_key).to eq :test
    end
  end
end
