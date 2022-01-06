# frozen_string_literal: true

RSpec.describe "Deprecated Dry::System.register_provider and Dry::System.register_component" do
  before do
    Object.send(:remove_const, :ExternalComponents) if defined? ExternalComponents

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

        register_provider(:my_logger, from: :external_components, source: :logger) do
          configure do |config|
            config.log_level = :debug
          end

          after(:start) do |external_container|
            register(:my_logger, external_container[:logger])
          end
        end
      end
    end

    Test::Container
  end

  it "registers source providers for the external components" do
    require SPEC_ROOT.join("fixtures/external_components_deprecated/lib/external_components")

    my_logger = container[:my_logger]

    expect(my_logger).to be_instance_of(ExternalComponents::Logger)
    expect(my_logger.log_level).to be(:debug)
  end

  it "prints deprecation warnings" do
    logger = StringIO.new
    Dry::Core::Deprecations.set_logger! logger

    require SPEC_ROOT.join("fixtures/external_components_deprecated/lib/external_components")

    logger.rewind
    expect(logger.string).to match(/Dry::System\.register_provider is deprecated.*Dry::System\.register_component is deprecated/m)
  end
end
