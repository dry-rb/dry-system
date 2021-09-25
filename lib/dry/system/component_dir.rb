# frozen_string_literal: true

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

      # Returns a component for the given key if a matching source file is found within
      # the component dir
      #
      # This searches according to the component dir's configured namespaces, in order of
      # definition, with the first match returned as the component.
      #
      # @param key [String] the component's key
      # @return [Dry::System::Component, nil] the component, if found
      #
      # @api private
      def component_for_identifier(key)
        namespaces.each do |namespace|
          identifier = Identifier.new(key, separator: container.config.namespace_separator)

          next unless identifier.start_with?(namespace.identifier_namespace)

          if (file_path = find_component_file(identifier, namespace))
            return build_component(identifier, namespace, file_path)
          end
        end

        nil
      end

      # TODO: support calling without block, returning enum
      def each_component
        each_file do |file_path, namespace|
          yield component_for_path(file_path, namespace)
        end
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
        if namespace.path?
          Dir["#{full_path}/#{namespace.path}/**/#{RB_GLOB}"].sort
        else
          non_root_paths = namespaces.to_a.reject(&:root?).map(&:path)

          Dir["#{full_path}/**/#{RB_GLOB}"].reject { |file_path|
            Pathname(file_path).relative_path_from(full_path).to_s.start_with?(*non_root_paths)
          }.sort
        end
      end

      # Returns the full path of the component directory
      #
      # @return [Pathname]
      def full_path
        container.root.join(path)
      end

      # Returns a component for a full path to a Ruby source file within the component dir
      #
      # @param path [String] the full path to the file
      # @return [Dry::System::Component] the component
      def component_for_path(path, namespace)
        separator = container.config.namespace_separator

        key = Pathname(path).relative_path_from(full_path).to_s
          .sub(RB_EXT, EMPTY_STRING)
          .scan(WORD_REGEX)
          .join(separator)

        identifier = Identifier.new(key, separator: separator)
          .namespaced(
            from: namespace.path&.gsub(PATH_SEPARATOR, separator),
            to: namespace.identifier_namespace
          )

        build_component(identifier, namespace, path)
      end

      def find_component_file(identifier, namespace)
        # To properly find the file within a namespace with an explicitly provided
        # identifier_namespace, we should strip the identifier_namespace from beginning of
        # our given identifier
        if namespace.identifier_namespace
          identifier = identifier.namespaced(from: namespace.identifier_namespace, to: nil)
        end

        file_name = "#{identifier.key_with_separator(PATH_SEPARATOR)}#{RB_EXT}"

        component_file =
          if namespace.path?
            full_path.join(namespace.path, file_name)
          else
            full_path.join(file_name)
          end

        component_file if component_file.exist?
      end

      def build_component(identifier, namespace, file_path)
        options = {
          inflector: container.config.inflector,
          **component_options,
          **MagicCommentsParser.(file_path)
        }

        Component.new(identifier, namespace: namespace, **options)
      end

      def component_options
        {
          auto_register: auto_register,
          loader: loader,
          memoize: memoize
        }
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
