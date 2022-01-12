# frozen_string_literal: true

require "dry/core/deprecations"
require_relative "constants"
require_relative "provider/source"

module Dry
  module System
    # Providers can prepare and register one or more objects and typically work with third
    # party code. A typical provider might be for a database library, or an API client.
    #
    # The particular behavior for any provider is defined in a {Provider::Source}, which
    # is a subclass created when you run {Container.register_provider} or
    # {Dry::System.register_provider_source}. The Source provides this behavior through
    # methods for each of the steps in the provider lifecycle: `prepare`, `start`, and
    # `run`. These methods typically create and configure various objects, then register
    # them with the {#provider_container}.
    #
    # The Provider manages this lifecycle by implementing common behavior around the
    # lifecycle steps, such as running step callbacks, and only running steps when
    # appropriate for the current status of the lifecycle.
    #
    # Providers can be registered via {Container.register_provider}.
    #
    # @example Simple provider
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
    # @example Using an external Provider Source
    #   class App < Dry::System::Container
    #     register_provider(:logger, from: :some_external_provider_source) do
    #       configure do |config|
    #         config.log_level = :debug
    #       end
    #
    #       after :start do
    #         register(:my_extra_logger, resolve(:logger))
    #       end
    #     end
    #   end
    #
    #   App[:my_extra_logger] # returns the extra logger registered in the callback
    #
    # @api public
    class Provider
      # Returns the provider's unique name.
      #
      # @return [Symbol]
      #
      # @api public
      attr_reader :name

      # Returns the default namespace for the provider's container keys.
      #
      # @return [Symbol,String]
      #
      # @api public
      attr_reader :namespace

      # Returns an array of lifecycle steps that have been run.
      #
      # @return [Array<Symbol>]
      #
      # @example
      #   provider.statuses # => [:prepare, :start]
      #
      # @api public
      attr_reader :statuses

      # Returns the container for the provider.
      #
      # This is where the provider's source will register its components, which are then
      # later marged into the target container after the `prepare` and `start` lifecycle
      # steps.
      #
      # @return [Dry::Container]
      #
      # @api public
      attr_reader :provider_container
      alias_method :container, :provider_container

      # Returns the target container for the provider.
      #
      # This is the container with which the provider is registered (via
      # {Dry::System::Container.register_provider}).
      #
      # Registered components from the provider's container will be merged into this
      # container after the `prepare` and `start` lifecycle steps.
      #
      # @return [Dry::System::Container]
      #
      # @api public
      attr_reader :target_container
      alias_method :target, :target_container

      # Returns the provider's source
      #
      # The source provides the specific behavior for the provider via methods
      # implementing the lifecycle steps.
      #
      # The provider's source is defined when registering a provider with the container,
      # or an external provider source.
      #
      # @see Dry::System::Container.register_provider
      # @see Dry::System.register_provider_source
      #
      # @return [Dry::System::Provider::Source]
      #
      # @api private
      attr_reader :source

      # @api private
      def initialize(name:, namespace: nil, target_container:, source_class:, &block) # rubocop:disable Style/KeywordParametersOrder
        @name = name
        @namespace = namespace
        @target_container = target_container

        @provider_container = build_provider_container
        @statuses = []

        @source = source_class.new(
          provider_container: provider_container,
          target_container: target_container,
          &block
        )
      end

      # Runs the `prepare` lifecycle step.
      #
      # Also runs any callbacks for the step, and then merges any registered components
      # from the provider container into the target container.
      #
      # @return [self]
      #
      # @api public
      def prepare
        run_step(:prepare)
      end

      # Runs the `start` lifecycle step.
      #
      # Also runs any callbacks for the step, and then merges any registered components
      # from the provider container into the target container.
      #
      # @return [self]
      #
      # @api public
      def start
        run_step(:prepare)
        run_step(:start)
      end

      # Runs the `stop` lifecycle step.
      #
      # Also runs any callbacks for the step.
      #
      # @return [self]
      #
      # @api public
      def stop
        return unless started?

        run_step(:stop)
      end

      # Returns true if the provider's `prepare` lifecycle step has run
      #
      # @api public
      def prepared?
        statuses.include?(:prepare)
      end

      # Returns true if the provider's `start` lifecycle step has run
      #
      # @api public
      def started?
        statuses.include?(:start)
      end

      # Returns true if the provider's `stop` lifecycle step has run
      #
      # @api public
      def stopped?
        statuses.include?(:stop)
      end

      private

      # @api private
      def build_provider_container
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

      # @api private
      def run_step(step_name)
        return self if statuses.include?(step_name)

        source.run_callback(:before, step_name)
        source.public_send(step_name)
        source.run_callback(:after, step_name)

        statuses << step_name

        apply

        self
      end

      # Registers any components from the provider's container in the main container.
      #
      # Called after each lifecycle step runs.
      #
      # @return [self]
      #
      # @api private
      def apply
        provider_container.each do |key, item|
          target_container.register(key, item) unless target_container.registered?(key)
        end

        self
      end
    end
  end
end
