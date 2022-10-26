# frozen_string_literal: true

require "dry/system/provider_sources"

RSpec.describe "Deprecated :settings provider source `key`" do
  before do
    # We don't care about the deprecation messages when we're not testing for them
    # specifically
    Dry::Core::Deprecations.set_logger!(StringIO.new)
  end

  subject(:container) {
    module Test
      class Container < Dry::System::Container
        setting :env

        configure do |config|
          config.root = __dir__
          config.env = :development
        end

        register_provider(:settings, from: :dry_system) do
          settings do
            key :some_int_using_deprecated_key, Dry::Types["coercible.integer"]
          end
        end
      end
    end

    Test::Container
  }

  before do
    ENV["SOME_INT_USING_DEPRECATED_KEY"] = "5"
  end

  after do
    ENV.delete("SOME_INT_USING_DEPRECATED_KEY")
  end

  it "defines the setting" do
    expect(container[:settings].some_int_using_deprecated_key).to eq 5
  end

  it "prints a deprecation notice" do
    logger = StringIO.new
    Dry::Core::Deprecations.set_logger! logger

    container.start(:settings)

    logger.rewind
    expect(logger.string).to match(/Dry::System :settings provider source setting definition using `key`.*Use `setting` instead, with dry-configurable `setting` options/m)
  end
end
