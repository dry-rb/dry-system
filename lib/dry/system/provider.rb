# frozen_string_literal: true

# The source environment provides `settings do`, which saves a list of settings

# The exec environment provides `configure do`, which _configures_ the previously saved
# settings, and saves them as `config`

# ---> .: the exec environment needs access to the source_environment

# Then, the step environment needs access to `config` so that the configuration can be
# used when setting up and registering components etc.

# ---> .: the step environment needs access to the exec_enviroment

# source_environment <- exec_environment <- step_environment

# (Later on we can toy with the idea of a "context" that can be a formal channel for
# extensible information sharing between these environments)


require "dry/core/deprecations"
require "dry/system/settings"
require "dry/system/components/config"
require "dry/system/constants"
# require_relative "provider/exec_environment"
# require_relative "provider/source_environment"
# require_relative "provider/step_environment"

require_relative "provider/source"
require_relative "provider/source_dsl"

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
      # attr_reader :source_environment, :exec_environment

      attr_reader :source

      def initialize(name:, namespace: nil, target_container:, source_block:, refinement_block: nil) # rubocop:disable Style/KeywordParametersOrder
        @name = name
        @namespace = namespace
        @target_container = target_container

        @container = build_container
        @statuses = []

        @source = SourceDSL.source_from(&source_block)
          .new(container: @container, target_container: @target_container, &refinement_block)

        # @source_environment = SourceEnvironment.new(self, &source_block)
        # @exec_environment = ExecEnvironment.new(self, @source_environment, &refinement_block)
        # @step_environment = StepEnvironment.new(self, @exec_environment)
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

      private def run_step(step_name)
        return self if statuses.include?(step_name)

        # source_environment.public_send(step_name)

        # WIP: hmmmmm, this right? We'll also need to provide access to the source
        # environment eventually if we want to permit custom methods
        # step = source_environment.method(step_name)
        # step_environment.instance_exec(target_container, &step)

        # exec_environment.call(step_name)

        # run_step_callbacks(:before, step_name)

        source.run_callback(:before, step_name)
        source.public_send(step_name)
        source.run_callback(:after, step_name)

        # step_block = source_environment.public_send(step_name) # TODO: wonder if there's a better way to retrieve this?
        # step_environment.call(target_container, &step_block) if step_block
        # self

        # run_step_callbacks(:after, step_name)

        statuses << step_name

        self
      end

      # private def run_step_callbacks(hook, step_name)
      #   exec_environment.callbacks_for(hook, step_name).each do |fn|
      #     target_container.instance_exec(container, &fn)
      #   end
      #   self
      # end

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
    end
  end
end
