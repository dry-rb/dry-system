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

          system.setting :ignored_dependencies, default: []

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
          dependency_key = key.to_s
          unless config.ignored_dependencies.include?(dependency_key)
            self[:notifications].instrument(
              :registered_dependency, key: dependency_key, class: self[dependency_key].class
            )
          end

          self
        end
      end
    end
  end
end
