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
      include Dry::Equalizer(:identifier, :namespace, :options)

      DEFAULT_OPTIONS = {
        separator: DEFAULT_SEPARATOR,
        inflector: Dry::Inflector.new,
        loader: Loader
      }.freeze

      # @!attribute [r] identifier
      #   @return [String] component's unique identifier
      attr_reader :identifier

      # TODO: docs
      attr_reader :namespace

      # @!attribute [r] options
      #   @return [Hash] component's options
      attr_reader :options

      # @api private
      def initialize(identifier, namespace:, **options)
        @identifier = identifier
        @namespace = namespace
        @options = DEFAULT_OPTIONS.merge(options)
      end

      # @api private
      def loadable?
        true
      end

      # Returns the component's instance
      #
      # @return [Object] component's class instance
      # @api public
      def instance(*args)
        loader.call(self, *args)
      end
      ruby2_keywords(:instance) if respond_to?(:ruby2_keywords, true)

      def key
        identifier.to_s
      end

      def root_key
        identifier.root_key
      end

      # TODO: update docs to reflect it's in component now
      #
      # Returns a path-delimited representation of the identifier, with the namespace
      # incorporated. This path is intended for usage when requiring the component's
      # source file.
      #
      # @example
      #   identifier.key # => "articles.operations.create"
      #   identifier.namespace # => "admin"
      #
      #   identifier.path # => "admin/articles/operations/create"
      #
      # @return [String] the path
      # @api public
      def require_path
        if namespace.path
          "#{namespace.path}/#{path_in_namespace}"
        else
          path_in_namespace
        end
      end

      # TODO: docs
      def const_path
        namespace_const_path = namespace.const_namespace&.gsub(identifier.separator, PATH_SEPARATOR)

        if namespace_const_path
          "#{namespace_const_path}/#{path_in_namespace}"
        else
          path_in_namespace
        end
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

      def path_in_namespace
        identifier_in_namespace =
          if namespace.identifier_namespace
            identifier.namespaced(from: namespace.identifier_namespace, to: nil)
          else
            identifier
          end

        identifier_in_namespace.key_with_separator(PATH_SEPARATOR)
      end

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
