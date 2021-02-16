require "pathname"
require_relative "constants"
require_relative "identifier"
require_relative "magic_comments_parser"

module Dry
  module System
    # A configured component directory within the container's root. Provides access to the
    # component directory's configuration, as well as methods for locating component files
    # within the directory
    #
    # @see Dry::System::Config::ComponentDir
    # @api private
    class ComponentDir
      # @!attribute [r] config
      #   @return [Dry::System::Config::ComponentDir] the component directory configuration
      #   @api private
      attr_reader :config

      # @!attribute [r] container
      #   @return [Dry::System::Container] the container managing the component directory
      #   @api private
      attr_reader :container

      # @api private
      def initialize(config:, container:)
        @config = config
        @container = container
      end

      # Returns a component for a given identifier if a matching component file could be
      # found within the component dir
      #
      # This will search within the component dir's configured default_namespace first,
      # then fall back to searching for a non-namespaced file
      #
      # @param identifier [String] the identifier string
      # @return [Dry::System::Component, nil] the component, if found
      #
      # @api private
      def component_for_identifier(identifier)
        identifier = Identifier.new(
          identifier,
          namespace: default_namespace,
          separator: container.config.namespace_separator
        )

        if (file_path = find_component_file(identifier.path))
          return build_component(identifier, file_path)
        end

        identifier = identifier.with(namespace: nil)
        if (file_path = find_component_file(identifier.path))
          build_component(identifier, file_path)
        end
      end

      # Returns a component for a full path to a Ruby source file within the component dir
      #
      # @param path [String] the full path to the file
      # @return [Dry::System::Component] the component
      #
      # @api private
      def component_for_path(path)
        separator = container.config.namespace_separator

        key = Pathname(path).relative_path_from(full_path).to_s
          .sub(RB_EXT, EMPTY_STRING)
          .scan(WORD_REGEX)
          .join(separator)

        identifier = Identifier.new(key, separator: separator)

        if identifier.start_with?(default_namespace)
          identifier = identifier.dequalified(default_namespace, namespace: default_namespace)
        end

        build_component(identifier, path)
      end

      # Returns the full path of the component directory
      #
      # @return [Pathname]
      # @api private
      def full_path
        container.root.join(path)
      end

      # Returns the explicitly configured loader for the component dir, otherwise the
      # default loader configured for the container
      #
      # @see Dry::System::Loader
      # @api private
      def loader
        config.loader || container.config.loader
      end

      # @api private
      def component_options
        {
          auto_register: auto_register,
          loader: loader,
          memoize: memoize,
        }
      end

      private

      def build_component(identifier, file_path)
        options = {
          inflector: container.config.inflector,
          **component_options,
          **MagicCommentsParser.(file_path)
        }

        Component.new(identifier, file_path: file_path, **options)
      end

      def find_component_file(component_path)
        component_file = full_path.join("#{component_path}#{RB_EXT}")
        component_file if component_file.exist?
      end

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, include_all = false)
        config.respond_to?(name) || super
      end
    end
  end
end
