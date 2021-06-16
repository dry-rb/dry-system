# frozen_string_literal: true

require "dry/system/config/component_dir"

RSpec.describe Dry::System::Config::ComponentDir do
  subject(:component_dir) { described_class.new("some_path") }

  describe "#default_namespace= (deprecated)" do
    before do
      # We don't care about the deprecation messages when we're not testing for them
      # specifically
      Dry::Core::Deprecations.set_logger!(StringIO.new)
    end

    it "adds a corresponding namespace object" do
      expect { component_dir.default_namespace = "admin" }
        .to change { component_dir.namespaces.namespaces.keys.to_a.length }
        .from(0).to(1)

      added_namespace = component_dir.namespaces.namespaces["admin"]

      expect(added_namespace).to be
      expect(added_namespace.path).to eq "admin"
      expect(added_namespace.key).to eq nil
      expect(added_namespace.const).to eq "admin"
    end

    it "converts dot-delimited namespace strings to equivalent paths" do
      component_dir.default_namespace = "nested.admin"

      added_namespace = component_dir.namespaces.namespaces["nested/admin"]

      expect(added_namespace).to be
      expect(added_namespace.path).to eq "nested/admin"
      expect(added_namespace.key).to eq nil
      expect(added_namespace.const).to eq "nested/admin"
    end

    it "adds the namespace object only once" do
      expect {
        component_dir.default_namespace = "admin"
        component_dir.default_namespace = "admin"
      }
        .to change { component_dir.namespaces.namespaces.keys.to_a.length }
        .from(0).to(1)
    end

    it "prints a deprecation warning" do
      logger = StringIO.new
      Dry::Core::Deprecations.set_logger! logger

      component_dir.default_namespace = "admin"

      logger.rewind
      expect(logger.string).to match(/ComponentDir#default_namespace= is deprecated/)
    end
  end

  describe "#default_namespace (deprecated)" do
    before do
      # We don't care about the deprecation messages when we're not testing for them
      # specifically
      Dry::Core::Deprecations.set_logger!(StringIO.new)
    end

    it "is nil by default" do
      expect(component_dir.default_namespace).to be_nil
    end

    it "returns the dot-delimited leading identifier string for the first configured namespace" do
      component_dir.default_namespace = "nested.admin"

      expect(component_dir.default_namespace).to eq "nested.admin"
    end

    it "prints a deprecation warning" do
      logger = StringIO.new
      Dry::Core::Deprecations.set_logger! logger

      component_dir.default_namespace

      logger.rewind
      expect(logger.string).to match(/ComponentDir#default_namespace is deprecated/)
    end
  end
end
