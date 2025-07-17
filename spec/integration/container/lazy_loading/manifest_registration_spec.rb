# frozen_string_literal: true

RSpec.describe "Lazy-loading registration manifest files" do
  module Test; end

  def build_container
    Class.new(Dry::System::Container) do
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/manifest_registration").realpath
      end
    end
  end

  shared_examples "manifest component" do
    before do
      Test::Container = build_container
      Test::Container.add_to_load_path!("lib")
    end

    it "loads a registration manifest file if the component could not be found" do
      expect(Test::Container["foo.special"]).to be_a(Test::Foo)
      expect(Test::Container["foo.special"].name).to eq "special"
    end
  end

  context "Non-finalized container" do
    include_examples "manifest component"
  end

  context "Finalized container" do
    include_examples "manifest component"
    before { Test::Container.finalize! }
  end

  context "Autoloaded container" do
    let :autoloader do
      Zeitwerk::Loader.new.tap do |loader|
        loader.enable_reloading

        # This is a simulacrum of the Dry::Rails container reset
        # that happens on every reload
        loader.on_setup do
          if Test.const_defined?(:Container)
            Test.__send__(:remove_const, :Container)
          end

          Test.const_set :Container, build_container
          Test::Container.finalize!

          loader.push_dir(Test::Container.root)
        end
      end
    end

    it "reloads manifest keys" do
      autoloader.setup
      expect(Test::Container.keys).to include("foo.special")

      autoloader.reload
      expect(Test::Container.keys).to include("foo.special")
    end
  end
end
