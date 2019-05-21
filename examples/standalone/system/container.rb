require 'dry/events'
require 'dry/monitor/notifications'
require 'dry/system/container'

class App < Dry::System::Container
  use :dependency_graph

  configure do |config|
    config.auto_register = %w(lib)
  end

  load_paths!('lib')
end
