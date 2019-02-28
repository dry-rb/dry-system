require 'dry/events/publisher'
require 'dry/system/plugins/plugin'
require 'dry/system_plugins/monitoring/proxy'
require 'dry/system_plugins/monitoring/mixin'

module Dry
  module SystemPlugins
    module Monitoring
      # @api public
      class Plugin < Dry::System::Plugin
        config.identifier = :monitoring

        # @api private
        def initialize(*args)
          super

          container.send(:extend, Mixin)
        end

        def after_configure(config)
          container[:notifications].register_event(:monitoring)
        end
      end
    end
  end
end
