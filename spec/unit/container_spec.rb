# frozen_string_literal: true

require "dry/system/container"
require "dry/system/stubs"

RSpec.describe Dry::System::Container do
  subject(:container) { Test::Container }

  context "with default core dir" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/test").realpath
          config.component_dirs.add "lib"
        end
      end

      module Test
        Import = Container.injector
      end
    end

    describe ".require_from_root" do
      it "requires a single file" do
        container.require_from_root(Pathname("lib/test/models"))

        expect(Test.const_defined?(:Models)).to be(true)
      end

      it "requires many files when glob pattern is passed" do
        container.require_from_root(Pathname("lib/test/models/*.rb"))

        expect(Test::Models.const_defined?(:User)).to be(true)
        expect(Test::Models.const_defined?(:Book)).to be(true)
      end
    end
  end

  describe ".init" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/lazytest").realpath
        end

        add_to_load_path!("lib")
      end
    end

    it "lazy-boot a given system" do
      container.init(:bar)

      expect(Test.const_defined?(:Bar)).to be(true)
      expect(container.registered?("test.bar")).to be(false)
    end
  end

  describe ".start" do
    shared_examples_for "a booted system" do
      it "boots a given system and finalizes it" do
        container.start(:bar)

        expect(Test.const_defined?(:Bar)).to be(true)
        expect(container["test.bar"]).to eql("I was finalized")
      end

      it "expects identifier to point to an existing boot file" do
        expect {
          container.start(:foo)
        }.to raise_error(
          ArgumentError,
          "component identifier +foo+ is invalid or boot file is missing"
        )
      end

      describe "mismatch betwenn finalize name and registered component" do
        it "raises a meaningful error" do
          expect {
            container.start(:hell)
          }.to raise_error(Dry::System::InvalidComponentIdentifierError)
        end
      end
    end

    context "with the default core dir" do
      it_behaves_like "a booted system" do
        before do
          class Test::Container < Dry::System::Container
            configure do |config|
              config.root = SPEC_ROOT.join("fixtures/test").realpath
            end

            add_to_load_path!("lib")
          end
        end
      end
    end

    context "with a bootable dir" do
      it_behaves_like "a booted system" do
        before do
          class Test::Container < Dry::System::Container
            configure do |config|
              config.root = SPEC_ROOT.join("fixtures/other").realpath
              config.bootable_dirs = ["config/boot"]
            end

            add_to_load_path!("lib")
          end
        end
      end
    end
  end

  describe ".stub" do
    let(:stubbed_car) do
      double(:car, wheels_count: 5)
    end

    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/stubbing").realpath
          config.component_dirs.add "lib"
        end
      end
    end

    describe "with stubs disabled" do
      it "raises error when trying to stub frozen container" do
        expect { container.stub("test.car", stubbed_car) }.to raise_error(NoMethodError, /stub/)
      end
    end

    describe "with stubs enabled" do
      before do
        container.enable_stubs!
      end

      it "lazy-loads a component" do
        # This test doens't really make sense
        # why do we test it again afterwards? It's also nothing to do with stubbing really...

        expect(container[:db]).to be_instance_of(Test::DB)

        # byebug
        container.finalize!
        expect(container[:db]).to be_instance_of(Test::DB)
      end

      it "allows to stub components" do
        container.finalize!

        expect(container["test.car"].wheels_count).to be(4)

        container.stub("test.car", stubbed_car)

        expect(container["test.car"].wheels_count).to be(5)
      end
    end
  end

  describe ".key?" do
    before do
      class Test::FalseyContainer < Dry::System::Container
        register(:else) { :else }
        register(:false) { false }
        register(:nil) { nil }
      end

      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/test").realpath
          config.component_dirs.add "lib"
        end

        importer.registry.update(falses: Test::FalseyContainer)
      end
    end

    it "tries to load component" do
      expect(container.key?("test.dep")).to be(true)
    end

    it "returns false for non-existing component" do
      expect(container.key?("test.missing")).to be(false)
    end

    it "returns true if registered value is false or nil" do
      expect(container.key?("falses.false")).to be(true)
      expect(container.key?("falses.nil")).to be(true)
    end
  end

  describe ".resolve" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/test").realpath
          config.component_dirs.add "lib"
        end
      end
    end

    it "runs a fallback block when a component cannot be resolved" do
      expect(container.resolve("missing") { :fallback }).to be(:fallback)
    end
  end

  describe ".registered?" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/test").realpath
          config.component_dirs.add "lib"
        end
      end
    end

    it "checks if a component is registered" do
      expect(container.registered?("test.dep")).to be(false)
      container.resolve("test.dep")
      expect(container.registered?("test.dep")).to be(true)
    end
  end
end
