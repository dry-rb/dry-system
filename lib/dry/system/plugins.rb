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
        def stateful?
          mod < Module
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
        @__registry__ ||= {}
      end

      # Enable a plugin
      #
      # Plugin identifier
      #
      # @param [Symbol] name The plugin identifier
      # @param [Hash] options Plugin options
      #
      # @return [self]
      #
      # @api public
      def use(name, options = {})
        unless enabled_plugins.include?(name)
          Plugins.registry[name].apply_to(self, options)
          enabled_plugins << name
        end
        self
      end

      # @api private
      def inherited(klass)
        klass.instance_variable_set(:@__enabled_plugins__, enabled_plugins.dup)
        super
      end

      # @api private
      def enabled_plugins
        @__enabled_plugins__ ||= []
      end

      require 'dry/system/plugins/bootsnap'
      register(:bootsnap, Plugins::Bootsnap)

      require 'dry/system/plugins/logging'
      register(:logging, Plugins::Logging)

      require 'dry/system/plugins/env'
      register(:env, Plugins::Env)

      require 'dry/system/plugins/decorate'
      register(:decorate, Plugins::Decorate)

      require 'dry/system/plugins/notifications'
      register(:notifications, Plugins::Notifications)

      require 'dry/system/plugins/monitoring'
      register(:monitoring, Plugins::Monitoring)
    end
  end
end
