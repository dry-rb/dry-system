# frozen_string_literal: true

require "dry/core/deprecations"
require_relative "constants"
require_relative "provider/source"

module Dry
  module System
    # Providers can prepare and register one or more objects and typically depend on
    # 3rd-party code. A typical provider might be for a database library, or an API
    # client.
    #
    # Providers can be registered via `Container.register_provider` and provider sources
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
    # @example using first-party provider sources
    #   class App < Dry::System::Container
    #     register_provider(:settings, from: :dry_system) do
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
      # @!attribute [r] key
      #   @return [Symbol] the provider's unique name
      attr_reader :name

      # attr_reader :step_environment

      # Returns a list of lifecycle steps that were executed
      #
      # @return [Array<Symbol>]
      #
      # @api public
      attr_reader :statuses

      # @!attribute [r] namespace
      #   @return [Symbol,String] default namespace for the container keys
      attr_reader :namespace

      attr_reader :provider_container

      # Returns the main container used by this provider
      #
      # @return [Dry::Struct]
      #
      # @api public
      attr_reader :target_container
      alias_method :target, :target_container

      attr_reader :source

      def initialize(name:, namespace: nil, target_container:, source_class: nil, &block) # rubocop:disable Style/KeywordParametersOrder
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
        return unless statuses.include?(:start)

        run_step(:stop)
      end

      # Returns true if the provider's `prepare` step has run
      #
      # @api public
      def prepared?
        statuses.include?(:prepare)
      end

      # Returns true if the provider's `start` step has run
      #
      # @api public
      def started?
        statuses.include?(:start)
      end

      # Returns true if the provider's `stop` step has run
      #
      # @api public
      def stopped?
        statuses.include?(:stop)
      end

      private

      # Return configured container for the lifecycle object
      #
      # @return [Dry::Container]
      #
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

      def run_step(step_name)
        return self if statuses.include?(step_name)

        source.run_callback(:before, step_name)
        source.public_send(step_name)
        source.run_callback(:after, step_name)

        statuses << step_name

        apply

        self
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
        provider_container.each do |key, item|
          target_container.register(key, item) unless target_container.registered?(key)
        end

        self
      end
    end
  end
end
