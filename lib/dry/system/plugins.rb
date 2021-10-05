# frozen_string_literal: true

require "dry/system/constants"

module Dry
  module System
    module Plugins
      # @api private
      class Plugin
        attr_reader :name

        attr_reader :mod

        attr_reader :block

        # @api private
        def initialize(name, mod, &block)
          @name = name
          @mod = mod
          @block = block
        end

        # @api private
        def apply_to(system, options)
          system.extend(stateful? ? mod.new(options) : mod)
          system.instance_eval(&block) if block
          system
        end

        # @api private
        def load_dependencies(dependencies = mod_dependencies, gem = nil)
          Array(dependencies).each do |dependency|
            if dependency.is_a?(Array) || dependency.is_a?(Hash)
              dependency.each { |value| load_dependencies(*Array(value).reverse) }
            elsif !Plugins.loaded_dependencies.include?(dependency.to_s)
              load_dependency(dependency, gem)
            end
          end
        end

        # @api private
        def load_dependency(dependency, gem)
          Kernel.require dependency
          Plugins.loaded_dependencies << dependency.to_s
        rescue LoadError => e
          raise PluginDependencyMissing.new(name, e.message, gem)
        end

        # @api private
        def stateful?
          mod < Module
        end

        # @api private
        def mod_dependencies
          return EMPTY_ARRAY unless mod.respond_to?(:dependencies)

          mod.dependencies.is_a?(Array) ? mod.dependencies : [mod.dependencies]
        end
      end

      # Register a plugin
      #
      # @param [Symbol] name The name of a plugin
      # @param [Class] plugin Plugin module
      #
      # @return [Plugins]
      #
      # @api public
      def self.register(name, plugin, &block)
        registry[name] = Plugin.new(name, plugin, &block)
      end

      # @api private
      def self.registry
        @registry ||= {}
      end

      # @api private
      def self.loaded_dependencies
        @loaded_dependencies ||= []
      end

      # Enables a plugin if not already enabled.
      # Raises error if plugin cannot be found in the plugin registry.
      #
      # @param [Symbol] name The plugin name
      # @param [Hash] options Plugin options
      #
      # @return [self]
      #
      # @api public
      def use(name, options = {})
        return self if enabled_plugins.include?(name)

        raise PluginNotFoundError, name unless (plugin = Plugins.registry[name])

        plugin.load_dependencies
        plugin.apply_to(self, options)

        enabled_plugins << name

        self
      end

      # @api private
      def inherited(klass)
        klass.instance_variable_set(:@enabled_plugins, enabled_plugins.dup)
        super
      end

      # @api private
      def enabled_plugins
        @enabled_plugins ||= []
      end

      require "dry/system/plugins/bootsnap"
      register(:bootsnap, Plugins::Bootsnap)

      require "dry/system/plugins/logging"
      register(:logging, Plugins::Logging)

      require "dry/system/plugins/env"
      register(:env, Plugins::Env)

      require "dry/system/plugins/notifications"
      register(:notifications, Plugins::Notifications)

      require "dry/system/plugins/monitoring"
      register(:monitoring, Plugins::Monitoring)

      require "dry/system/plugins/dependency_graph"
      register(:dependency_graph, Plugins::DependencyGraph)
    end
  end
end
