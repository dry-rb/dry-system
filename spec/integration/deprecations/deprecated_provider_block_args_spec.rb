# frozen_string_literal: true

RSpec.describe "Deprecated register_provider block arg" do
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
          config.root = __dir__
        end

        register_provider(:blorp) do |arg1|
          init do
            arg1.register "blorp", "my blorp"
          end
        end
      end
    end

    Test::Container
  }

  it "still allows access to the target container via a register_provider block arg" do
    expect(container["blorp"]).to eq "my blorp"
  end

  it "prints a deprecation notice" do
    logger = StringIO.new
    Dry::Core::Deprecations.set_logger! logger

    container.init :blorp

    logger.rewind
    expect(logger.string).to match(/Dry::System.register_provider with single block parameter is deprecated.*Use `target_container` \(or `target` for short\) inside your block instead/m)
  end
end
