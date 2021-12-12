# frozen_string_literal: true

require "dry/events"
require "dry/monitor/notifications"
require "dry/system/container"

class App < Dry::System::Container
  use :zeitwerk

  configure do |config|
    config.component_dirs.add "lib"
  end
end
