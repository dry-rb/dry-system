# frozen_string_literal: true

require "dry/system/container"

class App < Dry::System::Container
  use :env, inferrer: -> { ENV.fetch("RACK_ENV", :development).to_sym }
  use :zeitwerk, debug: true

  configure do |config|
    config.component_dirs.add "lib"
  end
end
