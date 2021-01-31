# frozen_string_literal: true

require "dry/inflector"
require "dry/system/loader"
require "singleton"
require "dry/system/component"

RSpec.describe Dry::System::Loader do
  subject(:loader) { described_class }

  describe "#require!" do
    let(:component) { Dry::System::Component.new("test.bar") }

    before do
      allow(loader).to receive(:require)
    end

    context "component file exists" do
      let(:component) { Dry::System::Component.new("test.bar", file_path: "path/to/test/bar.rb") }

      it "requires the components's path" do
        loader.require!(component)
        expect(loader).to have_received(:require).with "test/bar"
      end
    end

    context "component file does not exist" do
      it "does not require the components's path" do
        loader.require!(component)
        expect(loader).not_to have_received(:require)
      end
    end

    it "returns self" do
      expect(loader.require!(component)).to eql loader
    end
  end

  describe "#call" do
    shared_examples_for "object loader" do
      let(:instance) { loader.call(component) }

      context "not singleton" do
        it "returns a new instance of the constant" do
          expect(instance).to be_instance_of(constant)
          expect(instance).not_to be(loader.call(component))
        end
      end

      context "singleton" do
        before { constant.send(:include, Singleton) }

        it "returns singleton instance" do
          expect(instance).to be(constant.instance)
        end
      end
    end

    context "with a singular name" do
      let(:component) { Dry::System::Component.new("test.bar") }

      let(:constant) { Test::Bar }

      before do
        module Test; class Bar; end; end
      end

      it_behaves_like "object loader"
    end

    context "with a plural name" do
      let(:component) { Dry::System::Component.new("test.bars") }

      let(:constant) { Test::Bars }

      before do
        module Test; class Bars; end; end
      end

      it_behaves_like "object loader"
    end

    context "with a constructor accepting args" do
      let(:component) { Dry::System::Component.new("test.bar") }

      before do
        module Test
          Bar = Struct.new(:one, :two)
        end
      end

      it "passes args to the constructor" do
        instance = loader.call(component, 1, 2)

        expect(instance.one).to be(1)
        expect(instance.two).to be(2)
      end
    end

    context "with a custom inflector" do
      let(:component) {
        Dry::System::Component.new(
          "test.api_bar",
          inflector: Dry::Inflector.new { |i| i.acronym("API") }
        )
      }

      let(:constant) { Test::APIBar }

      before do
        Test::APIBar = Class.new
      end

      it_behaves_like "object loader"
    end
  end
end
