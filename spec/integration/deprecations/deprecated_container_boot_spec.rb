# frozen_string_literal: true

RSpec.describe "Deprecated Dry::System::Container.boot" do
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

        boot(:blorp) do
          start do
            register "blorp", "my blorp"
          end
        end

        boot(:my_logger, from: :external_components, key: :logger) do
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

  it "registers a provider via .register_provider" do
    expect(container["blorp"]).to eq "my blorp"
  end

  it "registers a provider using a source provider" do
    my_logger = container[:my_logger]

    expect(my_logger).to be_instance_of(ExternalComponents::Logger)
    expect(my_logger.log_level).to be(:debug)
  end

  it "prints deprecation warnings" do
    logger = StringIO.new
    Dry::Core::Deprecations.set_logger! logger

    container.finalize!

    logger.rewind
    expect(logger.string).to match(/Container\.boot is deprecated.*Container\.boot is deprecated/m)
  end
end
