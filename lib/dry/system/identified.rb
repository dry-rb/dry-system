require 'dry-equalizer'
require 'dry/system/constants'

module Dry
  module System
    # Identifiers are objects providing information about auto-registered files.
    # They are created on-demand when a key is requested that is not yet resolved.
    # They expose an API to query this information and use a configurable
    # loader object to initialize class instances.
    #
    # @api public
    class Identifier
      include Dry::Equalizer(:identifier, :namespace, :options)

      # @!attribute [r] options
      #   @return [Hash] identified's options
      attr_reader :options

      # @api private
      def initialize(identifier, namespace: nil, **options)
        @identifier = TO_SYM_ARRAY[identifier]
        @namespace = TO_SYM_ARRAY[namespace]
        @options = options
      end

      # @api private
      def boot?
        false
      end

      # @api private
      def file_exists?(paths)
        paths.any? { |path| path.join(file).exist? }
      end

      def namespace_prefixed?
        identifier_without_namespace != full_identifier
      end

      # @api private
      def prepend(name)
        self.class.new([name.to_sym, *@identifier], namespace: namespace, **options)
      end

      # @api private
      def namespaced(namespace)
        self.class.new(@identifier, namespace: namespace, **options)
      end

      # @api private
      def auto_register?
        !!options.fetch(:auto_register) { true }
      end

      # @api private
      def path
        @path ||= @identifier.join(PATH_SEPARATOR)
      end

      # @api private
      def file
        @file ||= "#{path}#{RB_EXT}"
      end

      # @api private
      def identifier
        @key ||= begin
          if identifier_without_namespace.size > 1
            identifier_without_namespace.join(DEFAULT_SEPARATOR)
          else
            identifier_without_namespace.first
          end
        end
      end

      # @api private
      def root_key
        identifier_without_namespace.first
      end

      # @api private
      def namespace
        return nil if @namespace.empty?
        return @namespace.first.to_sym if @namespace.size == 1
        @namespace.join(DEFAULT_SEPARATOR)
      end

      # @api private
      def full_identifier
        @identifier
      end

      def identifier_without_namespace
        @identifier_without_namespace ||= begin
          identifier = @identifier
          namespace = @namespace

          if identifier.first(namespace.size) == namespace
            identifier[namespace.size..-1]
          else
            identifier
          end
        end
      end
    end
  end
end
