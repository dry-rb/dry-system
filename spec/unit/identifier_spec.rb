# frozen_string_literal: true

require "dry/system/identifier"

RSpec.describe Dry::System::Identifier do
  subject(:identifier) { described_class.new(key, namespace: namespace, separator: separator) }

  let(:key) { "kittens.operations.belly_rub" }
  let(:namespace) { "my_app" }
  let(:separator) { "." }

  it "casts identifier to string" do
    expect(described_class.new(:db).identifier).to eq "db"
  end

  describe "#identifier" do
    it "is the identifier string in full" do
      expect(identifier.identifier).to eq "kittens.operations.belly_rub"
    end
  end

  describe "#key" do
    it "is an alias of #identifier" do
      expect(identifier.key).to eql identifier.identifier
    end
  end

  describe "#to_s" do
    it "returns the identifier string in full" do
      expect(identifier.to_s).to eq "kittens.operations.belly_rub"
    end
  end

  describe "#to_sym" do
    it "returns the identifier symbol in full" do
      expect(identifier.to_sym).to eq :"kittens.operations.belly_rub"
    end
  end

  describe "#root_key" do
    it "is the base segment of the identifier string, as a symbol" do
      expect(identifier.root_key).to eq :kittens
    end
  end

  describe "#path" do
    it "is the identifier string, preceded by the namespace, with separators converted to path separators" do
      expect(identifier.path).to eq "my_app/kittens/operations/belly_rub"
    end

    context "no namespace given" do
      let(:namespace) { nil }

      it "is the identifier string with separators converted to path separators" do
        expect(identifier.path).to eq "kittens/operations/belly_rub"
      end
    end
  end

  describe "#start_with?" do
    it "returns true when the provided string matches the base segment of the identifer string" do
      expect(identifier.start_with?("kittens")).to be true
    end

    it "returns true when the provided string matches multiple base segments of the identifer string" do
      expect(identifier.start_with?("kittens.operations")).to be true
    end

    it "returns false if the provided string is only a partial base segment" do
      expect(identifier.start_with?("kitten")).to be false
    end

    it "returns false if the provided string is not a base segment" do
      expect(identifier.start_with?("puppies")).to be false
    end
  end

  describe "#with" do
    it "returns a new identifier with the given namespace" do
      new_identifier = identifier.with(namespace: "another_app")

      expect(new_identifier).to be_an_instance_of(described_class)
      expect(new_identifier.key).to eql identifier.key
      expect(new_identifier.namespace).to eq "another_app"
      expect(new_identifier.separator).to eql identifier.separator
    end
  end

  describe "#dequalified" do
    it "returns a new identifier with the given base segments removed from the key" do
      new_identifier = identifier.dequalified("kittens.operations")

      expect(new_identifier).to be_an_instance_of(described_class)
      expect(new_identifier.key).to eq "belly_rub"
      expect(new_identifier.namespace).to eql identifier.namespace
      expect(new_identifier.separator).to eql identifier.separator
    end

    it "allows a new namespace to be given at the same time" do
      new_identifier = identifier.dequalified("kittens.operations", namespace: "another_app")
      expect(new_identifier.key).to eq "belly_rub"
      expect(new_identifier.namespace).to eql "another_app"
      expect(new_identifier.separator).to eql identifier.separator
    end
  end
end
