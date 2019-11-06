# frozen_string_literal: true

require 'dry/system/constants'
require 'dry/system/plugins/monitoring/proxy'

module Dry
  module System
    module Plugins
      # @api public
      module Monitoring
        # @api private
        def self.extended(system)
          super

          system.use(:notifications)

          system.after(:configure) do
            self[:notifications].register_event(:monitoring)
          end
        end

        # @api private
        def self.dependencies
          { 'dry-events': 'dry/events/publisher' }
        end

        # @api private
        def monitor(key, options = EMPTY_HASH, &block)
          notifications = self[:notifications]

          resolve(key).tap do |target|
            proxy = Proxy.for(target, options.merge(key: key))

            if block
              proxy.monitored_methods.each do |meth|
                notifications.subscribe(:monitoring, target: key, method: meth, &block)
              end
            end

            decorate(key, with: -> target { proxy.new(target, notifications) })
          end
        end
      end
    end
  end
end
