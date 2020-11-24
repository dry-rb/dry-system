# frozen_string_literal: true

require "dry/system/container"

RSpec.describe Dry::System::Container, ".auto_register!" do
  after do
    Object.send(:remove_const, :Foo) if defined? Foo
    Object.send(:remove_const, :Bar) if defined? Bar
  end

  context "standard loader" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").realpath
          config.component_dirs.add "components"
        end
      end
    end

    it { expect(Test::Container["foo"]).to be_an_instance_of(Foo) }
    it { expect(Test::Container["bar"]).to be_an_instance_of(Bar) }
    it { expect(Test::Container["bar.baz"]).to be_an_instance_of(Bar::Baz) }

    it "doesn't register files with inline option 'auto_register: false'" do
      expect(Test::Container.registered?("no_register")).to eql false
    end
  end

  context "with custom configuration block" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").realpath
          config.component_dirs.add "components"
        end
      end
    end

    it "exclude specific components" do
      Test::Container.auto_register!("components") do |config|
        config.instance(&:identifier)

        config.exclude do |component|
          component.path =~ /bar/
        end
      end

      expect(Test::Container["foo"]).to eql("foo")

      expect(Test::Container.registered?("bar")).to eql false
      expect(Test::Container.registered?("bar.baz")).to eql false
    end
  end

  describe "auto registration options" do
    let(:container) do
      Class.new(Dry::System::Container) do
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").realpath
          config.component_dirs.add "components"
        end
      end
    end

    context "with default registration options" do
      it "does not memoize results" do
        container.auto_register!("components")

        expect(container["foo"]).to be_an_instance_of(Foo)
        expect(container["foo"]).to_not be(container["foo"])
      end
    end

    context "with explicit overrides" do
      context "with memoization enabled" do
        it "memoizes results" do
          container.auto_register!("components") do |config|
            config.memoize = true
          end

          expect(container["foo"]).to be_an_instance_of(Foo)
          expect(container["foo"]).to be(container["foo"])
        end
      end

      context "with memoization disabled" do
        it "does not memoize results" do
          container.auto_register!("components") do |config|
            config.memoize = false
          end
          expect(container["foo"]).to be_an_instance_of(Foo)
          expect(container["foo"]).to_not be(container["foo"])
        end
      end
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
            # dir.default_namespace = "namespace"
          end
        end
      end
    end

    specify { expect(Test::Container["foo"]).to be_an_instance_of(Foo) }
    specify { expect(Test::Container["bar"]).to be_an_instance_of(Bar) }
    specify { expect(Test::Container["bar.baz"]).to be_an_instance_of(Bar::Baz) }
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
          config.component_dirs.add "components"
          config.loader = ::Test::Loader
        end
      end
    end

    it { expect(Test::Container["foo"]).to be_an_instance_of(Foo) }
    it { expect(Test::Container["bar"]).to eq(Bar) }
    it { expect(Test::Container["bar"].call).to eq("Welcome to my Moe's Tavern!") }
    it { expect(Test::Container["bar.baz"]).to be_an_instance_of(Bar::Baz) }
  end

  context "when component directory is missing" do
    context "in config" do
      before do
        class Test::Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures").realpath
            config.component_dirs.add "components"
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

    context "in auto_register! call" do
      before do
        class Test::Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures").realpath
          end
        end
      end

      it "warns about it" do
        expect {
          Test::Container.auto_register!("unknown_dir")
        }.to raise_error Dry::System::ComponentsDirMissing, %r{fixtures/unknown_dir}
      end
    end
  end
end
