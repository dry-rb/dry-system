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
      include Dry::Equalizer(:key, :separator)

      # @return [String] the identifier's string key
      # @api public
      attr_reader :key

      # @return [String] the configured namespace separator
      # @api public
      attr_reader :separator

      # @api private
      def initialize(key, separator: DEFAULT_SEPARATOR)
        @key = key.to_s
        @separator = separator
      end

      # @!method to_s
      #   Returns the identifier string key
      #
      #   @return [String]
      #   @see #key
      #   @api public
      alias_method :to_s, :key

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
      def start_with?(leading_namespaces)
        key.start_with?("#{leading_namespaces}#{separator}") || key.eql?(leading_namespaces)
      end

      # TODO: docs
      # TODO: better name? join
      def joined(separator)
        segments.join(separator)
      end

      # FIXME: update docs below for change from dequalified -> namespaced
      #
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
      def namespaced(from:, to:, **options)
        # TODO: need tests for this case
        return self if from == to

        # TODO: need tests for the `from.nil?` case
        new_key =
          if from.nil?
            "#{to}#{separator}#{key}"
          else
            key.sub(
              /^#{Regexp.escape(from.to_s)}#{Regexp.escape(separator)}/,
              to || EMPTY_STRING
            )
          end

        return self if new_key == key

        self.class.new(
          new_key,
          separator: separator,
          **options
        )
      end

      private

      def segments
        @segments ||= key.split(separator)
      end
    end
  end
end
