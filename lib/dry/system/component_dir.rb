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

        # FIXME: this is broken - we actually want to get all the files first, then sort
        # by namespaces, which would allow the `nil` namespace to go first, if provided
        # that way

        # Old way (not right):
        # (namespaces.map { |(path_namespace, _)|
        #   if path_namespace.nil?
        #     []
        #   else
        #     Dir["#{dir_path}/#{path_namespace}/**/#{RB_GLOB}"]
        #   end
        # }.flatten + Dir["#{dir_path}/**/#{RB_GLOB}"]).uniq.tap do |ff|
        #   # byebug
        # end

        # Original way (won't work anymore):
        # Dir["#{full_path}/**/#{RB_GLOB}"].sort

        ## Maybe correct? (but also hugely inefficient):

        ns_sort_map = namespaces.map.with_index { |(path_namespace, _), i|
          [
            path_namespace&.gsub(".", "/"), # FIXME make right
            i,
          ]
        }.to_h

        p ns_sort_map

        Dir["#{full_path}/**/#{RB_GLOB}"].sort_by { |file_path|
          # ns_sort_map

          sort = nil

          relative_file_path = Pathname(file_path).relative_path_from(full_path).to_s

          ns_sort_map.each do |prefix, sort_i|
            # byebug unless prefix.nil?
            next if prefix.nil?

            if relative_file_path.start_with?(prefix)
              sort = sort_i
              break
            end
          end

          if sort.nil?
            sort = ns_sort_map.fetch(nil, 999_999) # This was originally 0... But I think putting it at the end is actually the correct behaviour
          end

          puts "#{file_path}: #{sort}"
          sort
        }.tap do |ff|
          # byebug
        end
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
          # TODO: input validation of these namespace arrays in component dir config
          path_namespace, const_namespace = *namespace

          identifier = Identifier.new(
            identifier,
            path_namespace: path_namespace,
            const_namespace: const_namespace,
            separator: container.config.namespace_separator,
          )

          if (file_path = find_component_file(identifier.path))
            return build_component(identifier, file_path)
          end
        end

        nil
      end

      # Returns a component for a full path to a Ruby source file within the component dir
      #
      # @param path [String] the full path to the file
      # @return [Dry::System::Component] the component
      #
      # @api private
      def component_for_path(path)
        p path

        separator = container.config.namespace_separator

        key = Pathname(path).relative_path_from(full_path).to_s
          .sub(RB_EXT, EMPTY_STRING)
          .scan(WORD_REGEX)
          .join(separator)

        # nss = namespaces_by_specificity # Maybe don't need it now that the auto-registrar is giving things to us in the right order?
        nss = namespaces


        # byebug if key == "component"

        # What I actually want to do is create a matcher proc for each namespace, with the
        # matcher for the `nil` namespace (if provided) being the _absence_ of the other
        # namespaces



        ns_matchers = nss.map { |(key_ns, const_ns)|
          matcher =
            if key_ns.nil?
              # TODO: compile this into regexp so it's faster??
              non_nil_key_ns = nss.map(&:first).reject(&:nil?)
              -> path { non_nil_key_ns.none? { |ns| path.start_with?(ns) } }
            else
              -> path { path.start_with?(key_ns) }
            end

          [matcher, [key_ns, const_ns]]
        }.to_h
        # TODO: maybe add a nil one on the end if there isn't one already?

        # byebug if path =~ /admin_component/

        ns_matchers.each do |matcher, (key_ns, const_ns)|
          if matcher.(key)
            puts "matched ns: #{key_ns} / #{const_ns}"
            puts


            identifier = Identifier.new(
              key,
              separator: separator,
              path_namespace: key_ns,
              const_namespace: const_ns,
            )

            # byebug if path =~ /[^_]component/

            # Ugh, shouldn't be needed
            if key_ns.nil?
              return build_component(identifier, path)
            else
              identifier = identifier.dequalified(key_ns, require_path: "#{key.gsub('.', '/')}") # Ugh
              # byebug if path =~ /admin_component/
              return build_component(identifier, path)
            end
          end
        end

        # nss.each do |(path_namespace, const_namespace)|
        #   # FIXME: move the namespace assignment into building the component
        #   identifier = Identifier.new(
        #     key,
        #     separator: separator,
        #     path_namespace: path_namespace,
        #     const_namespace: const_namespace,
        #   )

        #   # byebug
        #   # byebug if key == "component"

        #   return build_component(identifier, path) if path_namespace.nil?

        #   if identifier.start_with?(path_namespace)
        #     identifier = identifier.dequalified(path_namespace, require_path: "#{key.gsub('.', '/')}")

        #     return build_component(identifier, path)
        #   end
        # end

        # TODO: is this needed?

        identifier = Identifier.new(
          key,
          separator: separator,
        )

        build_component(identifier, path)

        # namespaces.each do |(path_namespace, const_namespace)|
        #   identifier = Identifier.new(
        #     key,
        #     separator: separator,
        #     path_namespace: path_namespace,
        #     const_namespace: const_namespace,
        #   )

        #   if identifier.start_with?(path_namespace) # WIP
        #     identifier = identifier.dequalified(path_namespace) # WIP
        #   end
        # end
      end

      def namespaces_by_specificity
        # TODO: move to memoized private method
        @namespaces_by_specificity ||= namespaces.sort_by { |(path_namespace, _)|
          if path_namespace.nil?
            0
          else
            path_namespace.to_s.split(container.config.namespace_separator).length
          end
        }.reverse
      end

      def old_component_for_path(path)
        separator = container.config.namespace_separator

        key = Pathname(path).relative_path_from(full_path).to_s
          .sub(RB_EXT, EMPTY_STRING)
          .scan(WORD_REGEX)
          .join(separator)

        identifier = Identifier.new(key, separator: separator)

        if identifier.start_with?(namespaces) # WIP
          identifier = identifier.dequalified(namespaces, namespace: namespaces) # WIP
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
