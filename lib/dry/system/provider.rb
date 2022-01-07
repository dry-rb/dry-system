# frozen_string_literal: true

require "dry/core/deprecations"
require "dry/system/settings"
require "dry/system/components/config"
require "dry/system/constants"
require_relative "provider/source_definition"
require_relative "provider/step_evaluator"

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
      CALLBACK_MAP = Hash.new { |h, k| h[k] = [] }.freeze

      # @!attribute [r] key
      #   @return [Symbol] the provider's unique name
      attr_reader :name

      attr_reader :step_evaluator

      # Returns a list of lifecycle steps that were executed
      #
      # @return [Array<Symbol>]
      #
      # @api public
      attr_reader :step_statuses
      alias_method :statuses, :step_statuses

      # @!attribute [r] step_callbacks
      #   @return [Hash] lifecycle step after/before callbacks
      attr_reader :step_callbacks

      # @!attribute [r] namespace
      #   @return [Symbol,String] default namespace for the container keys
      attr_reader :namespace

      attr_reader :container

      # Returns the main container used by this provider
      #
      # @return [Dry::Struct]
      #
      # @api public
      attr_reader :target_container

      # Returns the lifecycle object used for this provider
      #
      # @return [ProviderLifecycle]
      #
      # @api private
      attr_reader :source_definition

      def initialize(name:, namespace: nil, target_container:, source_block:, refinement_block: nil) # rubocop:disable Style/KeywordParametersOrder
        @name = name
        @namespace = namespace
        @target_container = target_container

        @container = build_container
        @step_evaluator = StepEvaluator.new(self)
        @step_statuses = []
        @step_callbacks = {before: CALLBACK_MAP.dup, after: CALLBACK_MAP.dup}
        @config = nil
        @config_block = nil

        @source_definition = SourceDefinition.new(self, &source_block)
        instance_exec(&refinement_block) if refinement_block
      end

      # Execute `prepare` step
      #
      # @return [self]
      #
      # @api public
      def prepare
        run_step(:prepare)
      end

      # Execute `start` step
      #
      # @return [self]
      #
      # @api public
      def start
        run_step(:prepare)
        run_step(:start)
      end

      # Execute `stop` step
      #
      # @return [self]
      #
      # @api public
      def stop
        # FIXME real error
        raise "Why u trying to stop me when I haven't been started" unless statuses.include?(:start)

        run_step(:stop)
      end

      # Specify a before callback
      #
      # @return [self]
      #
      # @api public
      def before(event, &block)
        if event.to_sym == :init
          Dry::Core::Deprecations.announce(
            "Dry::System::Provider before(:init) callback",
            "Use `before(:prepare)` callback instead",
            tag: "dry-system",
            uplevel: 1
          )

          event = :prepare
        end

        step_callbacks[:before][event] << block
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
            "Dry::System::Provider after(:init) callback",
            "Use `after(:prepare)` callback instead",
            tag: "dry-system",
            uplevel: 1
          )

          event = :prepare
        end

        step_callbacks[:after][event] << block
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

      # Returns the provider's configuration
      #
      # @return [Dry::Struct]
      #
      # @api public
      def config
        @config || configure!
      end

      # Registers any components from the provider's container in the main container
      #
      # Automatically called by the booter after the `prepare` and `start` lifecycle
      # steps are run
      #
      # @return [self]
      #
      # @api private
      def apply
        container.each do |key, item|
          target_container.register(key, item) unless target_container.registered?(key)
        end
        self
      end

      private

      # Runs the given lifecycle step
      #
      # @return [self]
      def run_step(step_name)
        return self if step_statuses.include?(step_name)

        run_step_callbacks(:before, step_name)

        step_block = source_definition.public_send(step_name)
        step_evaluator.call(target_container, &step_block) if step_block
        step_statuses << step_name

        run_step_callbacks(:after, step_name)

        self
      end

      # Invokes a step callback
      #
      # @return [self]
      #
      # @api private
      def run_step_callbacks(key, event)
        step_callbacks[key][event].each do |fn|
          target_container.instance_exec(container, &fn)
        end
        self
      end

      # Return configured container for the lifecycle object
      #
      # @return [Dry::Container]
      #
      # @api private
      def build_container
        container = Dry::Container.new

        case namespace
        when String, Symbol
          container.namespace(namespace) { |c| return c }
        when true
          container.namespace(name) { |c| return c }
        when nil
          container
        else
          raise ArgumentError,
            "+namespace:+ must be true, string or symbol: #{namespace.inspect} given."
        end
      end

      # Set config object
      #
      # @return [Dry::Struct]
      #
      # @api private
      def configure!
        if source_definition.settings
          @config = source_definition.settings.new(Components::Config.new(&@config_block))
        end
      end
    end
  end
end
