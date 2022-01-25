# frozen_string_literal: true

RSpec.describe "Zeitwerk plugin / Eager loading" do
  include ZeitwerkHelpers

  after { teardown_zeitwerk }

  it "Eager loads after finalization" do
    app = Class.new(Dry::System::Container) do
      use :zeitwerk, eager_load: true

      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/zeitwerk_eager").realpath

        config.component_dirs.add "lib"
      end
    end

    expect { app.finalize! }
      .to change { global_variables }
      .to(a_collection_including(:$zeitwerk_eager_loaded))
  end

  it "Eager loads in production by default" do
    app = Class.new(Dry::System::Container) do
      use :env, inferrer: -> { :production }
      use :zeitwerk

      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/zeitwerk_eager_load_production").realpath

        config.component_dirs.add "lib"
      end
    end

    expect { app.finalize! }
      .to change { global_variables }
      .to(a_collection_including(:$zeitwerk_eager_load_production_loaded))
  end
end
