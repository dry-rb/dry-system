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

      def files
        dir_path = full_path

        raise ComponentDirNotFoundError, dir_path unless Dir.exist?(dir_path)

        ns_sort_map = namespaces.to_a.map.with_index { |namespace, i|
          [
            # FIXME: should just use namespace.path?
            # namespace.identifier_namespace&.gsub(".", "/"), # FIXME make right
            namespace.path,
            i,
          ]
        }.to_h

        Dir["#{full_path}/**/#{RB_GLOB}"].sort_by { |file_path|
          sort = nil

          relative_file_path = Pathname(file_path).relative_path_from(full_path).to_s

          ns_sort_map.each do |prefix, sort_i|
            next if prefix.nil?

            if relative_file_path.start_with?(prefix)
              sort = sort_i
              break
            end
          end

          if sort.nil?
            sort = ns_sort_map.fetch(nil, 999_999) # This was originally 0... But I think putting it at the end is actually the correct behaviour
          end

          sort
        }
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
          identifier = Identifier.new(
            identifier,
            base_path: namespace.path,
            identifier_namespace: namespace.identifier_namespace,
            const_namespace: namespace.const_namespace,
            separator: container.config.namespace_separator,
          )

          if (file_path = find_component_file(identifier.path))
            return build_component(identifier, file_path)
          end
        end

        nil
      end

      # WIP
      # Along with this, I think I might want to
      def each_component(&block)
        # TODO: support calling without block, returning enum
        files.each do |file_path|
          yield component_for_path(file_path)
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

        relative_path = Pathname(path).relative_path_from(full_path).to_s

        key = relative_path
          .sub(RB_EXT, EMPTY_STRING)
          .scan(WORD_REGEX)
          .join(separator)

        ns_matchers = namespaces.to_a.map { |namespace|
          matcher =
            if namespace.root?
              # TODO: compile this into regexp so it's faster??
              non_nil_key_ns = namespaces.to_a.reject(&:root?).map(&:path)
              -> path { non_nil_key_ns.none? { |ns| path.start_with?(ns) } }
            else
              -> path { path.start_with?(namespace.path) }
            end

          [matcher, namespace]
        }.to_h

        ns_matchers.each do |matcher, namespace|
          if matcher.(relative_path)
            identifier = Identifier.new(
              key,
              base_path: namespace.path,
              separator: separator,
              identifier_namespace: namespace.identifier_namespace,
              const_namespace: namespace.const_namespace,
            )
              .namespaced(
                from: namespace.path&.gsub(PATH_SEPARATOR, separator),
                to: namespace.identifier_namespace,
                require_path: "#{key.gsub('.', '/')}" # TODO: move to component
              )

            return build_component(identifier, path)
          end
        end

        # TODO: is this needed?

        identifier = Identifier.new(
          key,
          separator: separator,
        )

        build_component(identifier, path)
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

      def new_find_component_file(sub_path, component_path)
        component_file = full_path.join(*sub_path, "#{component_path}#{RB_EXT}")
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
