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
      #   @return [String] the component's unique identifier
      attr_reader :identifier

      # @!attribute [r] namespace
      #   @return [Dry::System::Config::Namespace] the component's namespace
      attr_reader :namespace

      # @!attribute [r] options
      #   @return [Hash] the component's options
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
        identifier.key
      end

      def root_key
        identifier.root_key
      end

      # Returns a path-delimited representation of the compnent, appropriate for passing
      # to `Kernel#require` to require its source file
      #
      # The path takes into account the rules of the namespace used to load the component.
      #
      # @example Component from a root namespace
      #   component.key # => "articles.create"
      #   component.require_path # => "articles/create"
      #
      # @example Component from an "admin/" path namespace (with `key_namespace: nil`)
      #   component.key # => "articles.create"
      #   component.require_path # => "admin/articles/create"
      #
      # @see Config::Namespaces#add
      # @see Config::Namespace
      #
      # @return [String] the require path
      #
      # @api public
      def require_path
        if namespace.path
          "#{namespace.path}#{FILE_SEPARATOR}#{path_in_namespace}"
        else
          path_in_namespace
        end
      end

      # Returns an "underscored", path-delimited representation of the component,
      # appropriate for passing to the inflector for constantizing
      #
      # The const path takes into account the rules of the namespace used to load the
      # component.
      #
      # @example Component from a namespace with `const_namespace: nil`
      #   component.key # => "articles.create_article"
      #   component.const_path # => "articles/create_article"
      #   component.inflector.constantize(component.const_path) # => Articles::CreateArticle
      #
      # @example Component from a namespace with `const_namespace: "admin"`
      #   component.key # => "articles.create_article"
      #   component.const_path # => "admin/articles/create_article"
      #   component.inflector.constantize(component.const_path) # => Admin::Articles::CreateArticle
      #
      # @see Config::Namespaces#add
      # @see Config::Namespace
      #
      # @return [String] the const path
      #
      # @api public
      def const_path
        namespace_const_path = namespace.const_namespace&.gsub(identifier.separator, PATH_SEPARATOR)

        if namespace_const_path
          "#{namespace_const_path}#{FILE_SEPARATOR}#{path_in_namespace}"
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
          if namespace.key_namespace
            identifier.namespaced(from: namespace.key_namespace, to: nil)
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
