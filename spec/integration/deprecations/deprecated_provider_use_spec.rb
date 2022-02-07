# frozen_string_literal: true

RSpec.describe "Deprecated Provider#use" do
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

        register_provider(:use_1) do
          start do
            register "use_1", "use_1"
          end
        end

        register_provider(:use_2) do
          start do
            register "use_2", "use_2"
          end
        end

        register_provider(:blorp) do
          start do
            use :use_1, :use_2
          end
        end
      end
    end

    Test::Container
  }

  it "starts the given providers" do
    expect { container.start :blorp }
      .to change { container.registered?("use_1") }.to(true)
      .and change { container.registered?("use_2") }.to(true)
  end

  it "prints a deprecation notice" do
    logger = StringIO.new
    Dry::Core::Deprecations.set_logger! logger

    container.start :blorp

    logger.rewind
    expect(logger.string).to match(/Dry::System::Provider#use is deprecated.*Use `target_container.start` instead/m)
  end
end
