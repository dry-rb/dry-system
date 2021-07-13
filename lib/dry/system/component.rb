# frozen_string_literal: true

require "concurrent/map"

require "dry/core/equalizer"
require "dry/inflector"
require "dry/system/loader"
require "dry/system/errors"
require "dry/system/constants"
require_relative "identifier"

module Dry
  module System
    # Components are objects providing information about auto-registered files.
    # They expose an API to query this information and use a configurable
    # loader object to initialize class instances.
    #
    # @api public
    class Component
      include Dry::Equalizer(:identifier, :file_path, :options)

      DEFAULT_OPTIONS = {
        separator: DEFAULT_SEPARATOR,
        inflector: Dry::Inflector.new,
        loader: Loader
      }.freeze

      # @!attribute [r] identifier
      #   @return [String] component's unique identifier
      attr_reader :identifier

      # @!attribute [r] file_path
      #   @return [String, nil] full path to the component's file, if found
      attr_reader :file_path

      # @!attribute [r] options
      #   @return [Hash] component's options
      attr_reader :options

      # @api private
      def self.new(identifier, options = EMPTY_HASH)
        options = DEFAULT_OPTIONS.merge(options)

        identifier =
          if identifier.is_a?(Identifier)
            identifier
          else
            # TODO: remove the need for this branch

            base_path = options.delete(:base_path)
            identifier_namespace = options.delete(:identifier_namespace)
            const_namespace = options.delete(:const_namespace)
            separator = options.delete(:separator)

            Identifier.new(
              identifier,
              base_path: base_path,
              identifier_namespace: identifier_namespace,
              const_namespace: const_namespace,
              separator: separator
            )
          end

        super(identifier, **options)
      end

      # @api private
      def initialize(identifier, file_path: nil, **options)
        @identifier = identifier
        @file_path = file_path
        @options = options
      end

      # Returns the component's instance
      #
      # @return [Object] component's class instance
      # @api public
      def instance(*args)
        loader.call(self, *args)
      end
      ruby2_keywords(:instance) if respond_to?(:ruby2_keywords, true)

      # @api private
      def bootable?
        false
      end

      def key
        identifier.to_s
      end

      def path
        identifier.path
      end

      def root_key
        identifier.root_key
      end

      # Returns true if the component has a corresponding file
      #
      # @return [Boolean]
      # @api private
      def file_exists?
        !!file_path
      end

      # @api private
      def loader
        options.fetch(:loader)
      end

      # @api private
      def inflector
        options.fetch(:inflector)
      end

      # @api private
      def auto_register?
        callable_option?(options[:auto_register])
      end

      # @api private
      def memoize?
        callable_option?(options[:memoize])
      end

      private

      def callable_option?(value)
        if value.respond_to?(:call)
          !!value.call(self)
        else
          !!value
        end
      end
    end
  end
end
