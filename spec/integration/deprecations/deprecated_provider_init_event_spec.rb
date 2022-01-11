# frozen_string_literal: true

RSpec.describe "Deprecated provider init event" do
  before do
    Object.send(:remove_const, :ExternalComponents) if defined? ExternalComponents
    require SPEC_ROOT.join("fixtures/external_components/lib/external_components")

    # We don't care about the deprecation messages when we're not testing for them
    # specifically
    Dry::Core::Deprecations.set_logger!(StringIO.new)
  end

  subject(:container) do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/app").realpath
        end

        register_provider(:blorp) do
          init do
            register "blorp", "my blorp"
          end
        end

        register_provider(:my_logger, from: :external_components, source: :logger) do
          configure do |config|
            config.log_level = :debug
          end

          before(:init) do
            register "before_init", "my before init"
          end

          after(:init) do
            register "after_init", "my after init"
          end
        end
      end
    end

    Test::Container
  end

  describe "init event in provider lifecycle" do
    it "uses the prepare event" do
      container.prepare :blorp
      expect(container.registered?("blorp")).to be true
    end

    it "prints a deprecation notice" do
      logger = StringIO.new
      Dry::Core::Deprecations.set_logger! logger

      container.init :blorp

      logger.rewind
      expect(logger.string).to match(/Dry::System::Provider::SourceDSL.*#init is deprecated/m)
    end
  end

  describe "before/after init triggers in providers using provider sources" do
    it "triggers the hooks around the prepare event" do
      container.prepare :my_logger
      expect(container["before_init"]).to eq "my before init"
      expect(container["after_init"]).to eq "my after init"
    end

    it "prints a deprecation notice" do
      logger = StringIO.new
      Dry::Core::Deprecations.set_logger! logger

      container.prepare :my_logger

      logger.rewind
      expect(logger.string).to match(/Dry::System::Provider before\(:init\) callback is deprecated.*Dry::System::Provider after\(:init\) callback is deprecated/m)
    end
  end

  describe "Container.init" do
    it "forwards to Container.prepare" do
      container.init :blorp
      expect(container.registered?("blorp")).to be true
    end

    it "prints a deprecation notice" do
      logger = StringIO.new
      Dry::Core::Deprecations.set_logger! logger

      container.init :blorp

      logger.rewind
      expect(logger.string).to match(/Dry::System::Container.*#init is deprecated/m)
    end
  end
end
