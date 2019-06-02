# frozen_string_literal: true

require 'dry/system/container'

class App < Dry::System::Container
  load_paths!('lib', 'system')

  auto_register!('lib') do |config|
    config.memoize = true
    config.instance do |component|
      # some custom initialization logic
      component.instance
    end

    config.exclude do |component|
      component.path =~ /entities/
    end
  end
end
