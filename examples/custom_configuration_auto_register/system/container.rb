# frozen_string_literal: true

require 'dry/system/container'

class App < Dry::System::Container
  load_paths!('lib', 'system')

  auto_register!('lib') do |config|
    config.memoize = true
    config.instance(&:instance)

    config.exclude do |component|
      component.path =~ /entities/
    end
  end
end
