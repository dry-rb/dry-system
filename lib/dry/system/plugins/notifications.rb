module Dry
  module System
    module Plugins
      # @api public
      module Notifications
        # @api private
        def self.extended(system)
          system.after(:configure, &:register_notifications)
        end

        # @api private
        def register_notifications
          return self if key?(:notifications)
          require 'dry/monitor/notifications' unless Object.const_defined?('Dry::Monitor::Notifications')
          register(:notifications, Monitor::Notifications.new(config.name))
        end
      end
    end
  end
end
