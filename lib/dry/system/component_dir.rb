require "pathname"
require "dry/system/constants"
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
      # # WIP
      # FIXME: REMOVE THIS WIP COMMENT ABOVE
      # This will search within the component dir's configured namespaces first, # WIP
      # then fall back to searching for a non-namespaced file
      #
      # @param identifier [String] the identifier string
      # @return [Dry::System::Component, nil] the component, if found
      #
      # @api private
      def component_for_identifier(identifier)
        namespaces.each do |namespace|
          identifier = Identifier.new(identifier, separator: container.config.namespace_separator)

          if (file_path = find_component_file(identifier, namespace))
            return build_component(identifier, namespace, file_path)
          end
        end

        nil
      end

      # TODO: support calling without block, returning enum
      def each_component(&block)
        each_file do |file_path, namespace|
          yield component_for_path(file_path, namespace)
        end
      end

      # Returns the full path of the component directory
      #
      # @return [Pathname]
      # @api private
      def full_path
        container.root.join(path)
      end

      # @api private
      def component_options
        {
          auto_register: auto_register,
          loader: loader,
          memoize: memoize
        }
      end

      private

      def each_file
        raise ComponentDirNotFoundError, full_path unless Dir.exist?(full_path)

        namespaces.each do |namespace|
          files(namespace).each do |file|
            yield file, namespace
          end
        end
      end

      def files(namespace)
        if !namespace.root?
          Dir["#{full_path}/#{namespace.path}/**/#{RB_GLOB}"].sort
        else
          non_root_paths = namespaces.to_a.reject(&:root?).map(&:path)

          Dir["#{full_path}/**/#{RB_GLOB}"].reject { |file_path|
            Pathname(file_path).relative_path_from(full_path).to_s.start_with?(*non_root_paths)
          }.sort
        end
      end

      # Returns a component for a full path to a Ruby source file within the component dir
      #
      # @param path [String] the full path to the file
      # @return [Dry::System::Component] the component
      #
      # @api private
      def component_for_path(path, namespace)
        separator = container.config.namespace_separator

        relative_path = Pathname(path).relative_path_from(full_path).to_s

        key = relative_path
          .sub(RB_EXT, EMPTY_STRING)
          .scan(WORD_REGEX)
          .join(separator)

        identifier = Identifier.new(key, separator: separator)
          .namespaced(
            from: namespace.path&.gsub(PATH_SEPARATOR, separator),
            to: namespace.identifier_namespace,
          )

        build_component(identifier, namespace, path)
      end

      def build_component(identifier, namespace, file_path)
        options = {
          inflector: container.config.inflector,
          **component_options,
          **MagicCommentsParser.(file_path)
        }

        Component.new(identifier, namespace: namespace, file_path: file_path, **options)
      end

      def find_component_file(identifier, namespace)
        file_name = "#{identifier.joined(PATH_SEPARATOR)}#{RB_EXT}"

        component_file =
          if namespace.path?
            full_path.join(namespace.path, file_name)
          else
            full_path.join(file_name)
          end

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
