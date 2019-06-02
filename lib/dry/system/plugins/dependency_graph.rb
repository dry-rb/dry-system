# frozen_string_literal: true

require 'dry/system/constants'
require 'dry/system/plugins/dependency_graph/strategies'

module Dry
  module System
    module Plugins
      # @api public
      module DependencyGraph
        # @api private
        def self.extended(system)
          super

          system.use(:notifications)

          system.setting :ignored_dependencies, [:notifications]

          system.after(:configure) do
            self[:notifications].register_event(:resolved_dependency)
            self[:notifications].register_event(:registered_dependency)

            system.strategies(Stratagies.with_notifications(system[:notifications]))
          end
        end

        # @api private
        def self.dependencies
          'dry/events/publisher'
        end

        # @api private
        def register(key, contents = nil, options = {}, &block)
          unless config.ignored_dependencies.include?(key.to_sym)
            notifications = self[:notifications]
            notifications.instrument(:registered_dependency, key: key)
          end

          super
        end
      end
    end
  end
end
