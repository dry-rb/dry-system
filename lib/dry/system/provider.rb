# frozen_string_literal: true

require "dry/core/deprecations"
require "dry/system/provider_lifecycle"
require "dry/system/settings"
require "dry/system/components/config"
require "dry/system/constants"

module Dry
  module System
    # Providers can prepare and register one or more objects and typically depend on
    # 3rd-party code. A typical provider might be for a database library, or an API
    # client.
    #
    # Providers can be registered via `Container.register_provider` and source providers
    # can register their components too, which then can be used and configured by your
    # system.
    #
    # @example simple logger
    #   class App < Dry::System::Container
    #     register_provider(:logger) do
    #       prepare do
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
    # @example using first-party source providers
    #   class App < Dry::System::Container
    #     register_provider(:settings, from: :system) do
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
    class Provider
      TRIGGER_MAP = Hash.new { |h, k| h[k] = [] }.freeze

      # @!attribute [r] key
      #   @return [Symbol] the provider's unique name
      attr_reader :name

      # @!attribute [r] triggers
      #   @return [Hash] lifecycle step after/before callbacks
      attr_reader :triggers

      # @!attribute [r] namespace
      #   @return [Symbol,String] default namespace for the container keys
      attr_reader :namespace

      # Returns the main container used by this provider
      #
      # @return [Dry::Struct]
      #
      # @api public
      attr_reader :container

      # Returns the block that will be evaluated in the lifecycle context
      #
      # @return [Proc]
      #
      # @api private
      attr_reader :lifecycle_block

      def initialize(name:, namespace: nil, container:, lifecycle_block:, refinement_block: nil) # rubocop:disable Style/KeywordParametersOrder
        @name = name
        @namespace = namespace
        @container = container
        @lifecycle_block = lifecycle_block

        @triggers = {before: TRIGGER_MAP.dup, after: TRIGGER_MAP.dup}
        @config = nil
        @config_block = nil

        instance_exec(&refinement_block) if refinement_block
      end

      # Execute `prepare` step
      #
      # @return [self]
      #
      # @api public
      def prepare
        trigger(:before, :prepare)
        lifecycle.(:prepare)
        trigger(:after, :prepare)
        self
      end

      # Execute `start` step
      #
      # @return [self]
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
      # @return [self]
      #
      # @api public
      def stop
        lifecycle.(:stop)
        self
      end

      # Specify a before callback
      #
      # @return [self]
      #
      # @api public
      def before(event, &block)
        if event.to_sym == :init
          Dry::Core::Deprecations.announce(
            "Dry::System::Provider before(:init) trigger",
            "Use `before(:prepare)` trigger instead",
            tag: "dry-system",
            uplevel: 1
          )

          event = :prepare
        end

        triggers[:before][event] << block
        self
      end

      # Specify an after callback
      #
      # @return [self]
      #
      # @api public
      def after(event, &block)
        if event.to_sym == :init
          Dry::Core::Deprecations.announce(
            "Dry::System::Provider after(:init) trigger",
            "Use `after(:prepare)` trigger instead",
            tag: "dry-system",
            uplevel: 1
          )

          event = :prepare
        end

        triggers[:after][event] << block
        self
      end

      # Configures the provider
      #
      # @return [self]
      #
      # @api public
      def configure(&block)
        @config_block = block
        self
      end

      # Define configuration settings with keys and types
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

      # Returns the provider's configuration
      #
      # @return [Dry::Struct]
      #
      # @api public
      def config
        @config || configure!
      end

      # Returns a list of lifecycle steps that were executed
      #
      # @return [Array<Symbol>]
      #
      # @api public
      def statuses
        lifecycle.statuses
      end

      # Registers any components from the provider's container in the main container
      #
      # Automatically called by the booter after the `prepare` and `start` lifecycle
      # triggers are run
      #
      # @return [self]
      #
      # @api private
      def apply
        lifecycle.container.each do |key, item|
          container.register(key, item) unless container.registered?(key)
        end
        self
      end

      # Trigger a callback
      #
      # @return [self]
      #
      # @api private
      def trigger(key, event)
        triggers[key][event].each do |fn|
          container.instance_exec(lifecycle.container, &fn)
        end
        self
      end

      private

      # Returns the lifecycle object used for this provider
      #
      # @return [ProviderLifecycle]
      #
      # @api private
      def lifecycle
        @lifecycle ||= ProviderLifecycle.new(lf_container, component: self, &lifecycle_block)
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
        @config = settings.new(Components::Config.new(&@config_block)) if settings
      end
    end
  end
end
