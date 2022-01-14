# frozen_string_literal: true

require "dry/system/identifier"

RSpec.describe Dry::System::Identifier do
  subject(:identifier) { described_class.new(key) }

  let(:key) { "kittens.operations.belly_rub" }

  describe "#key" do
    it "returns the identifier's key" do
      expect(identifier.key).to eql "kittens.operations.belly_rub"
    end

    context "non-string key given" do
      let(:key) { :db }

      it "converts to a string" do
        expect(identifier.key).to eq "db"
      end
    end
  end

  describe "#to_s" do
    it "returns the key" do
      expect(identifier.to_s).to eq "kittens.operations.belly_rub"
    end
  end

  describe "#root_key" do
    it "returns the base segment of the key, as a symbol" do
      expect(identifier.root_key).to eq :kittens
    end
  end

  describe "#start_with?" do
    it "returns true when the provided string matches the base segment of the identifier string" do
      expect(identifier.start_with?("kittens")).to be true
    end

    it "returns true when the provided string matches multiple base segments of the identifier string" do
      expect(identifier.start_with?("kittens.operations")).to be true
    end

    it "returns false if the provided string is only a partial base segment" do
      expect(identifier.start_with?("kitten")).to be false
    end

    it "returns false if the provided string is not a base segment" do
      expect(identifier.start_with?("puppies")).to be false
    end

    it "returns true when the provided string matches all segments of the identifier string" do
      expect(identifier.start_with?("kittens.operations.belly_rub")).to be true
    end

    it "returns true when the provided string is nil" do
      expect(identifier.start_with?(nil)).to be true
    end

    context "component is identified by a single segment" do
      let(:key) { "belly_rub" }

      it "returns true when the provided string matches the identifier string" do
        expect(identifier.start_with?("belly_rub")).to be true
      end

      it "returns false when the provided string does not match the identifier string" do
        expect(identifier.start_with?("belly_ruby")).to be false
      end
    end
  end

  describe "#key_with_separator" do
    it "returns the key split by the given separator" do
      expect(identifier.key_with_separator("/")).to eq "kittens/operations/belly_rub"
    end
  end

  describe "#namespaced" do
    let(:new_identifier) { identifier.namespaced(from: from, to: to, **opts) }

    let(:from) { "kittens" }
    let(:to) { "cats" }
    let(:opts) { {} }

    it "returns a new identifier" do
      expect(new_identifier).to be_an_instance_of(described_class)
    end

    it "replaces the leading namespace" do
      expect(new_identifier.key).to eq "cats.operations.belly_rub"
    end

    context "multiple leading namespaces" do
      let(:from) { "kittens.operations" }

      it "replaces the namespaces" do
        expect(new_identifier.key).to eq "cats.belly_rub"
      end
    end

    context "removing the leading namespace" do
      let(:to) { nil }

      it "removes the namespace" do
        expect(new_identifier.key).to eq "operations.belly_rub"
      end
    end

    context "adding a leading namespace" do
      let(:from) { nil }

      it "adds the namespace" do
        expect(new_identifier.key).to eq "cats.kittens.operations.belly_rub"
      end
    end

    it "returns itself if the key is unchanged" do
      expect(identifier.namespaced(from: nil, to: nil)).to be identifier
    end
  end
end
