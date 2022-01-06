# frozen_string_literal: true

RSpec.describe "Deprecated bootable_dirs config" do
  before do
    # We don't care about the deprecation messages when we're not testing for them
    # specifically
    Dry::Core::Deprecations.set_logger!(StringIO.new)
  end

  context "no explicit bootable_dirs config" do
    subject(:container) do
      module Test
        class Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures/deprecations/bootable_dirs_config").realpath
          end
        end
      end

      Test::Container
    end

    it "uses 'system/boot' if it exists" do
      container.start :logger
      expect(container["logger"]).to eq "my logger"
    end

    it "prints a deprecation notice" do
      logger = StringIO.new
      Dry::Core::Deprecations.set_logger! logger

      container.start :logger

      logger.rewind
      expect(logger.string).to match(/Dry::System::Container\.config\.bootable_dirs.+is deprecated/m)
    end
  end

  context "explicit bootable_dirs config" do
    subject(:container) do
      module Test
        class Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures/deprecations/bootable_dirs_config").realpath
            config.bootable_dirs = ["system/custom_boot"]
          end
        end
      end

      Test::Container
    end

    it "uses the bootable_dirs config" do
      container.start :logger
      expect(container["logger"]).to eq "my logger"
    end

    it "prints a deprecation notice" do
      logger = StringIO.new
      Dry::Core::Deprecations.set_logger! logger

      container.start :logger

      logger.rewind
      expect(logger.string).to match(/Dry::System::Container\.config\.bootable_dirs.+is deprecated/m)
    end
  end
end
