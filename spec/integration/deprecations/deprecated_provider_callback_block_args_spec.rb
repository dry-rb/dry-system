# frozen_string_literal: true

RSpec.describe "Deprecated provider callback block arg" do
  before do
    Object.send(:remove_const, :ExternalComponents) if defined? ExternalComponents
    require SPEC_ROOT.join("fixtures/external_components/lib/external_components")

    # We don't care about the deprecation messages when we're not testing for them
    # specifically
    Dry::Core::Deprecations.set_logger!(StringIO.new)
  end

  subject(:container) {
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/app").realpath
        end

        register_provider(:my_logger, from: :external_components, source: :logger) do
          configure do |config|
            config.log_level = :debug
          end

          after(:start) do |arg1|
            arg1.register(:my_logger, arg1.resolve(:logger))
          end
        end
      end
    end

    Test::Container
  }

  it "still allows access to the provider container via a provider step callback block arg" do
    expect(container[:my_logger]).to be_instance_of(ExternalComponents::Logger)
  end

  it "prints a deprecation notice" do
    logger = StringIO.new
    Dry::Core::Deprecations.set_logger! logger

    container.start(:my_logger)

    logger.rewind
    expect(logger.string).to match(/Dry::System::Provider::Source.before and .after callbacks with single block parameter is deprecated.*Use `provider_container` \(or `container` for short\) inside your block instead/m)
  end
end
