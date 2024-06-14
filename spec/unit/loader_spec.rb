# frozen_string_literal: true

require "dry/system/loader"

require "dry/inflector"
require "dry/system/component"
require "dry/system/config/namespace"
require "dry/system/identifier"
require "singleton"

RSpec.describe Dry::System::Loader do
  subject(:loader) { described_class }

  describe "#require!" do
    let(:component) {
      Dry::System::Component.new(
        Dry::System::Identifier.new("test.bar"),
        file_path: "/path/to/test/bar.rb",
        namespace: Dry::System::Config::Namespace.default_root
      )
    }

    before do
      expect(loader).to receive(:require).with("test/bar").at_least(1)
    end

    it "requires the components's path" do
      loader.require!(component)
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
      let(:component) {
        Dry::System::Component.new(
          Dry::System::Identifier.new("test.bar"),
          file_path: "/path/to/test/bar.rb",
          namespace: Dry::System::Config::Namespace.default_root
        )
      }

      let(:constant) { Test::Bar }

      before do
        expect(loader).to receive(:require).with("test/bar").at_least(1)

        module Test
          Bar = Class.new
        end
      end

      it_behaves_like "object loader"

      it "isolates component by removing its constant" do
        constant
        instance = loader.call(component, isolate: true)
        expect(Test.const_defined?("Bar")).to eq(false)
        expect(instance).to be_a(constant)
      end
    end

    context "with a constructor accepting args" do
      let(:component) {
        Dry::System::Component.new(
          Dry::System::Identifier.new("test.bar"),
          file_path: "/path/to/test/bar.rb",
          namespace: Dry::System::Config::Namespace.default_root
        )
      }

      before do
        expect(loader).to receive(:require).with("test/bar").at_least(1)

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
          Dry::System::Identifier.new("test.api_bar"),
          file_path: "/path/to/test/api_bar.rb",
          namespace: Dry::System::Config::Namespace.default_root,
          inflector: Dry::Inflector.new { |i| i.acronym("API") }
        )
      }

      let(:constant) { Test::APIBar }

      before do
        expect(loader).to receive(:require).with("test/api_bar").at_least(1)

        Test::APIBar = Class.new
      end

      it_behaves_like "object loader"
    end
  end

  describe "#constant" do
    let(:component) {
      Dry::System::Component.new(
        Dry::System::Identifier.new("test.api_bar"),
        file_path: "/path/to/test/api_bar.rb",
        namespace: Dry::System::Config::Namespace.default_root,
        inflector: Dry::Inflector.new { |i| i.acronym("API") }
      )
    }
    describe "successful constant loading" do
      before do
        Test::APIBar = Class.new
      end

      it "returns the constant" do
        expect(loader.constant(component)).to eq(Test::APIBar)
      end
    end

    describe "unsuccessful constant loading" do
      before do
        Test::APIBoo = Class.new
      end

      it "raises custom error" do
        expect { loader.constant(component) }.to raise_error(
          Dry::System::ComponentNotLoadableError
        ).with_message(
          <<~ERROR_MESSAGE.chomp
            Component 'test.api_bar' is not loadable.
            Looking for Test::APIBar.

            Did you mean?  Test::APIBoo
          ERROR_MESSAGE
        )
      end
    end
  end
end
