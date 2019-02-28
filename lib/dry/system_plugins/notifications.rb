require 'dry/monitor/notifications'
require 'dry/system/plugins/plugin'

module Dry
  module SystemPlugins
    # @api public
    class Notifications < Dry::System::Plugin
      config.identifier = :notifications

      def after_configure(config)
        @config = config

        container.register(:notifications, instance)
      end

      def instance
        @instance ||= Monitor::Notifications.new(config.name)
      end
    end
  end
end
