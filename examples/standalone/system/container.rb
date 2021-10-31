# frozen_string_literal: true

require "dry/events"
require "dry/monitor/notifications"
require "dry/system/container"

class App < Dry::System::Container
  use :dependency_graph

  configure do |config|
    config.component_dirs.add "lib" do |dir|
      dir.add_to_load_path = true # defaults to true
      dir.auto_register = lambda do |component|
        !component.identifier.start_with?("not_registered")
      end
    end
  end
end
