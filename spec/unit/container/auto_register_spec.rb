# frozen_string_literal: true

require "dry/system/container"

RSpec.describe Dry::System::Container, ".auto_register!" do
  context "standard loader" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").realpath
          config.component_dirs.add "components" do |dir|
            dir.default_namespace = "test"
          end
        end
      end
    end

    it { expect(Test::Container["foo"]).to be_an_instance_of(Test::Foo) }
    it { expect(Test::Container["bar"]).to be_an_instance_of(Test::Bar) }
    it { expect(Test::Container["bar.baz"]).to be_an_instance_of(Test::Bar::Baz) }

    it "doesn't register files with inline option 'auto_register: false'" do
      expect(Test::Container.registered?("no_register")).to eql false
    end
  end

  context "standard loader with a default namespace configured" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").realpath
          config.component_dirs.add "namespaced_components" do |dir|
            dir.default_namespace = "namespaced"
          end
        end
      end
    end

    specify { expect(Test::Container["bar"]).to be_a(Namespaced::Bar) }
    specify { expect(Test::Container["bar"].foo).to be_a(Namespaced::Foo) }
    specify { expect(Test::Container["foo"]).to be_a(Namespaced::Foo) }
  end

  context "standard loader with default namespace but boot files without" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").realpath

          config.component_dirs.add "components" do |dir|
            dir.default_namespace = "test"
          end
        end
      end
    end

    specify { expect(Test::Container["foo"]).to be_an_instance_of(Test::Foo) }
    specify { expect(Test::Container["bar"]).to be_an_instance_of(Test::Bar) }
    specify { expect(Test::Container["bar.baz"]).to be_an_instance_of(Test::Bar::Baz) }
  end

  context "standard loader with a default namespace with multiple level" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").realpath
          config.component_dirs.add "multiple_namespaced_components" do |dir|
            dir.default_namespace = "multiple.level"
          end
        end
      end
    end

    specify { expect(Test::Container["baz"]).to be_a(Multiple::Level::Baz) }
    specify { expect(Test::Container["foz"]).to be_a(Multiple::Level::Foz) }
  end

  context "with a custom loader" do
    before do
      class Test::Loader < Dry::System::Loader
        def call(*args)
          require!
          constant.respond_to?(:call) ? constant : constant.new(*args)
        end
      end

      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").realpath
          config.component_dirs.add "components" do |dir|
            dir.default_namespace = "test"
          end
          config.loader = ::Test::Loader
        end
      end
    end

    it { expect(Test::Container["foo"]).to be_an_instance_of(Test::Foo) }
    it { expect(Test::Container["bar"]).to eq(Test::Bar) }
    it { expect(Test::Container["bar"].call).to eq("Welcome to my Moe's Tavern!") }
    it { expect(Test::Container["bar.baz"]).to be_an_instance_of(Test::Bar::Baz) }
  end

  context "when component directory is missing" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").realpath
          config.component_dirs.add "components" do |dir|
            dir.default_namespace = "test"
          end
          config.component_dirs.add "unknown_dir"
        end
      end
    end

    it "warns about it" do
      expect {
        Test::Container.finalize!
      }.to raise_error Dry::System::ComponentsDirMissing, %r{fixtures/unknown_dir}
    end
  end
end
