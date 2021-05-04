# frozen_string_literal: true

require "dry/core/equalizer"
require_relative "constants"

module Dry
  module System
    # An identifier representing a component to be registered.
    #
    # Components are eventually registered in the container using plain string
    # identifiers, available as the `identifier` or `key` attribute here. Additional
    # methods are provided to make it easier to evaluate or manipulate these identifiers.
    #
    # @api public
    class Identifier
      include Dry::Equalizer(:identifier, :namespace, :separator)

      # @return [String] the identifier string
      # @api public
      attr_reader :identifier

      # @return [String, nil] the namespace for the component
      # @api public
      attr_reader :namespace

      # @return [String] the configured namespace separator
      # @api public
      attr_reader :separator

      # @api private
      def initialize(identifier, namespace: nil, separator: DEFAULT_SEPARATOR)
        @identifier = identifier.to_s
        @namespace = namespace
        @separator = separator
      end

      # @!method key
      #   Returns the identifier string
      #
      #   @return [String]
      #   @see #identifier
      #   @api public
      alias_method :key, :identifier

      # @!method to_s
      #   Returns the identifier string
      #
      #   @return [String]
      #   @see #identifier
      #   @api public
      alias_method :to_s, :identifier

      # Returns the root namespace segment of the identifier string, as a symbol
      #
      # @example
      #   identifier.key # => "articles.operations.create"
      #   identifier.root_key # => :articles
      #
      # @return [Symbol] the root key
      # @api public
      def root_key
        segments.first.to_sym
      end

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
      def path
        @require_path ||= identifier.gsub(separator, PATH_SEPARATOR).yield_self { |path|
          if namespace
            namespace_path = namespace.to_s.gsub(separator, PATH_SEPARATOR)
            "#{namespace_path}#{PATH_SEPARATOR}#{path}"
          else
            path
          end
        }
      end

      # Returns true if the given namespace prefix is part of the identifier's leading
      # namespaces
      #
      # @example
      #   identifier.key # => "articles.operations.create"
      #
      #   identifier.start_with?("articles.operations") # => true
      #   identifier.start_with?("articles") # => true
      #   identifier.start_with?("article") # => false
      #
      # @param leading_namespaces [String] the one or more leading namespaces to check
      # @return [Boolean]
      # @api public
      def start_with?(leading_segments_string)
        leading_segments = leading_segments_string.split(separator)
        identifier_segments = identifier.split(separator)
        identifier_segments.first(leading_segments.length) == leading_segments
      end

      # Returns a copy of the identifier with the given leading namespaces removed from
      # the identifier string.
      #
      # Additional options may be provided, which are passed to #initialize when
      # constructing the new copy of the identifier
      #
      # @param leading_namespace [String] the one or more leading namespaces to remove
      # @param options [Hash] additional options for initialization
      #
      # @return [Dry::System::Identifier] the copy of the identifier
      #
      # @see #initialize
      # @api private
      def dequalified(leading_namespaces, **options)
        new_identifier = identifier.gsub(
          /^#{Regexp.escape(leading_namespaces)}#{Regexp.escape(separator)}/,
          EMPTY_STRING
        )

        return self if new_identifier == identifier

        self.class.new(
          new_identifier,
          namespace: namespace,
          separator: separator,
          **options
        )
      end

      # Returns a copy of the identifier with the given options applied
      #
      # @param namespace [String, nil] a new namespace to be used
      #
      # @return [Dry::System::Identifier] the copy of the identifier
      #
      # @see #initialize
      # @api private
      def with(namespace:)
        self.class.new(
          identifier,
          namespace: namespace,
          separator: separator
        )
      end

      private

      def segments
        @segments ||= identifier.split(separator)
      end
    end
  end
end
