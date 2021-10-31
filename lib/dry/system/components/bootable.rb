# frozen_string_literal: true

require "dry/system/lifecycle"
require "dry/system/settings"
require "dry/system/components/config"
require "dry/system/constants"

module Dry
  module System
    module Components
      # Bootable components can provide one or more objects and typically depend
      # on 3rd-party code. A typical bootable component can be a database library,
      # or an API client.
      #
      # These components can be registered via `Container.boot` and external component
      # providers can register their components too, which then can be used and configured
      # by your system.
      #
      # @example simple logger
      #   class App < Dry::System::Container
      #     boot(:logger) do
      #       init do
      #         require "logger"
      #       end
      #
      #       start do
      #         register(:logger, Logger.new($stdout))
      #       end
      #     end
      #   end
      #
      #   App[:logger] # returns configured logger
      #
      # @example using built-in system components
      #   class App < Dry::System::Container
      #     boot(:settings, from: :system) do
      #       settings do
      #         key :database_url, Types::String.constrained(filled: true)
      #         key :session_secret, Types::String.constrained(filled: true)
      #       end
      #     end
      #   end
      #
      #   App[:settings] # returns loaded settings
      #
      # @api public
      class Bootable
        DEFAULT_FINALIZE = proc {}

        # @!attribute [r] key
        #   @return [Symbol] component's unique name
        attr_reader :name

        # @!attribute [r] options
        #   @return [Hash] component's options
        attr_reader :options

        # @!attribute [r] triggers
        #   @return [Hash] lifecycle step after/before callbacks
        attr_reader :triggers

        # @!attribute [r] namespace
        #   @return [Symbol,String] default namespace for the container keys
        attr_reader :namespace

        TRIGGER_MAP = Hash.new { |h, k| h[k] = [] }.freeze

        # @api private
        def initialize(name, options = {}, &block)
          @config = nil
          @config_block = nil
          @name = name
          @triggers = {before: TRIGGER_MAP.dup, after: TRIGGER_MAP.dup}
          @options = block ? options.merge(block: block) : options
          @namespace = options[:namespace]
          finalize = options[:finalize] || DEFAULT_FINALIZE
          instance_exec(&finalize)
        end

        # Execute `init` step
        #
        # @return [Bootable]
        #
        # @api public
        def init
          trigger(:before, :init)
          lifecycle.(:init)
          trigger(:after, :init)
          self
        end

        # Execute `start` step
        #
        # @return [Bootable]
        #
        # @api public
        def start
          trigger(:before, :start)
          lifecycle.(:start)
          trigger(:after, :start)
          self
        end

        # Execute `stop` step
        #
        # @return [Bootable]
        #
        # @api public
        def stop
          lifecycle.(:stop)
          self
        end

        # Specify a before callback
        #
        # @return [Bootable]
        #
        # @api public
        def before(event, &block)
          triggers[:before][event] << block
          self
        end

        # Specify an after callback
        #
        # @return [Bootable]
        #
        # @api public
        def after(event, &block)
          triggers[:after][event] << block
          self
        end

        # Configure a component
        #
        # @return [Bootable]
        #
        # @api public
        def configure(&block)
          @config_block = block
        end

        # Define configuration settings with keys and types
        #
        # @return [Bootable]
        #
        # @api public
        def settings(&block)
          if block
            @settings_block = block
          elsif @settings_block
            @settings = Settings::DSL.new(&@settings_block).call
          else
            @settings
          end
        end

        # Return component's configuration
        #
        # @return [Dry::Struct]
        #
        # @api public
        def config
          @config || configure!
        end

        # Return a list of lifecycle steps that were executed
        #
        # @return [Array<Symbol>]
        #
        # @api public
        def statuses
          lifecycle.statuses
        end

        # Return system's container used by this component
        #
        # @return [Dry::Struct]
        #
        # @api public
        def container
          options.fetch(:container)
        end

        # Automatically called by the booter object after starting a component
        #
        # @return [Bootable]
        #
        # @api private
        def finalize
          lifecycle.container.each do |key, item|
            container.register(key, item) unless container.registered?(key)
          end
          self
        end

        # Trigger a callback
        #
        # @return [Bootable]
        #
        # @api private
        def trigger(key, event)
          triggers[key][event].each do |fn|
            container.instance_exec(lifecycle.container, &fn)
          end
          self
        end

        # Return a new instance with updated name and options
        #
        # @return [Dry::Struct]
        #
        # @api private
        def new(name, new_options = EMPTY_HASH)
          self.class.new(name, options.merge(new_options))
        end

        # Return a new instance with updated options
        #
        # @return [Dry::Struct]
        #
        # @api private
        def with(new_options)
          self.class.new(name, options.merge(new_options))
        end

        private

        # Return lifecycle object used for this component
        #
        # @return [Lifecycle]
        #
        # @api private
        def lifecycle
          @lifecycle ||= Lifecycle.new(lf_container, component: self, &block)
        end

        # Return configured container for the lifecycle object
        #
        # @return [Dry::Container]
        #
        # @api private
        def lf_container
          container = Dry::Container.new

          case namespace
          when String, Symbol
            container.namespace(namespace) { |c| return c }
          when true
            container.namespace(name) { |c| return c }
          when nil
            container
          else
            raise <<-STR
              +namespace+ boot option must be true, string or symbol #{namespace.inspect} given.
            STR
          end
        end

        # Set config object
        #
        # @return [Dry::Struct]
        #
        # @api private
        def configure!
          @config = settings.new(Config.new(&@config_block)) if settings
        end

        # Return block that will be evaluated in the lifecycle context
        #
        # @return [Proc]
        #
        # @api private
        def block
          options.fetch(:block)
        end
      end
    end
  end
end
