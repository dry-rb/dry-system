# frozen_string_literal: true

require "dry/system/constants"
require "dry/system/plugins/dependency_graph/strategies"

module Dry
  module System
    module Plugins
      # @api public
      module DependencyGraph
        # @api private
        def self.extended(system)
          super

          system.use(:notifications)

          system.before(:configure) do
            setting :ignored_dependencies, []
          end

          system.after(:configure) do
            self[:notifications].register_event(:resolved_dependency)
            self[:notifications].register_event(:registered_dependency)

            strategies(Strategies)
          end
        end

        # @api private
        def self.dependencies
          {'dry-events': "dry/events/publisher"}
        end

        # @api private
        def register(key, contents = nil, options = {}, &block)
          super

          unless config.ignored_dependencies.include?(key.to_sym)
            self[:notifications].instrument(
              :registered_dependency, key: key, class: self[key].class
            )
          end

          self
        end
      end
    end
  end
end
