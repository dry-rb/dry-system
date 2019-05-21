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
          system.strategies(Stratagies)

          system.after(:configure) do
            self[:notifications].register_event(:resolved_dependency)
            self[:notifications].register_event(:registered_dependency)
          end
        end

        # @api private
        def self.dependencies
          'dry/events/publisher'
        end
      end
    end
  end
end
