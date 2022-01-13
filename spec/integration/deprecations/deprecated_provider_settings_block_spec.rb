# frozen_string_literal: true

RSpec.describe "Deprecated provider settings block" do
  before do
    # We don't care about the deprecation messages when we're not testing for them
    # specifically
    Dry::Core::Deprecations.set_logger!(StringIO.new)
  end

  subject(:container) {
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = __dir__
        end

        Dry::System.register_provider_source(:some_provider, group: :some_group) do
          settings do
            key :some_int, Dry::Types["coercible.integer"]
          end
        end

        register_provider(:my_provider, from: :some_group, source: :some_provider) do
          configure do |config|
            config.some_int = "12"
          end
        end
      end
    end

    Test::Container
  }

  it "uses the block to declare settings" do
    container.start :my_provider
    expect(container.providers[:my_provider].source.config.to_h).to eq(some_int: 12)
  end

  it "prints a deprecation notice" do
    logger = StringIO.new
    Dry::Core::Deprecations.set_logger! logger

    container

    logger.rewind
    expect(logger.string).to match(/Dry::System.register_provider with nested settings block is deprecated.*Use individual top-level `setting` declarations instead/m)
  end
end
