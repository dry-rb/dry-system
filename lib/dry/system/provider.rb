require 'dry/system/constants'

module Dry
  module System
    # Bootable providers can provide one or more objects and typically depend
    # on 3rd-party code. A typical bootable provider can be a database library,
    # or an API client.
    #
    # These providers can be registered via `Container.boot` and external component
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
    # @example using built-in system providers
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
    class Provider
      include Dry::Equalizer(:identifier, :system, :namespace)

      attr_reader :definition_block, :callbacks_block

      attr_reader :boot_block, :init_block, :start_block, :stop_block, :settings_block
      attr_reader :triggers, :configure_block, :dependencies, :provides

      # @!attribute [r] identifier
      #   @return [Symbol] provider's unique identifier
      attr_reader :identifier

      # @!attribute [r] system
      #   @return [Symbol] provider's system's (if any) unique identifier
      attr_reader :system

      # @!attribute [r] namespace
      #   @return [Symbol,String] default namespace for the container keys
      attr_reader :namespace

      # @!attribute [r] options
      #   @return [Hash] provider's options
      attr_reader :options

      # @api private
      def initialize(identifier, system = nil, definition: nil, callbacks: nil, **options, &block)
        definition ||= block
        @identifier = identifier.to_sym
        @system = system&.to_sym
        @options = options

        namespace = options[:namespace]
        @namespace = namespace && case namespace
          when true           then identifier
          when Symbol, String then namespace
          else
            raise RuntimeError, "+namespace+ boot option must be true, string or symbol: #{namespace.inspect} given."
          end

        @triggers = { before: Hash.new { |h, k| h[k] = [] }, after: Hash.new { |h, k| h[k] = [] } }

        @dependencies = []
        @provides = []

        @definition_block = definition
        @callbacks_block = callbacks
      end

      def new(**new_options)
        self.class.new(@identifier, @system, definition: @definition_block, **options.merge(new_options))
      end

      def boot!(context)
        instance_exec(context, &@definition_block)
        instance_exec(context, &@callbacks_block) if @callbacks_block

        provides(identifier) if @provides&.empty?

        self
      end

      def use(*args)
        @dependencies.concat(args)
      end

      def provides(*args)
        if args.size == 1 && args.first.nil?
          @provides = nil
        else
          @provides.concat(args.map(&TO_SYM_ARRAY))
        end
      end

      # Define configuration settings with keys and types
      #
      # @return [Bootable]
      #
      # @api public
      def settings(&block)
        @settings_block = block
      end

      # @api private
      def boot(&block)
        @boot_block = block
      end

      # @api private
      def init(&block)
        @init_block = block
      end

      # @api private
      def start(&block)
        @start_block = block
      end

      # @api private
      def stop(&block)
        @stop_block = block
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

      # Configure a provider
      #
      # @return [Bootable]
      #
      # @api public
      def configure(&block)
        @configure_block = block
      end
    end
  end
end
