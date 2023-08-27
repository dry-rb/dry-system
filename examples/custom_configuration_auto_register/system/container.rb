# frozen_string_literal: true

require "dry/system"

class App < Dry::System::Container
  configure do |config|
    config.component_dirs.add "lib" do |dir|
      dir.memoize = true

      dir.auto_register = lambda do |component|
        !component.identifier.start_with?("entities")
      end
    end
  end
end
