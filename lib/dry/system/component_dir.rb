require "pathname"
require_relative "constants"

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

      # Returns the full path for a component file within the directory, or nil if none if
      # exists
      #
      # @return [Pathname, nil]
      # @api private
      def component_file(component_path)
        if default_namespace
          namespace_path = default_namespace.gsub(DEFAULT_SEPARATOR, PATH_SEPARATOR)
          component_path = "#{namespace_path}#{PATH_SEPARATOR}#{component_path}"
        end

        component_file = full_path.join("#{component_path}#{RB_EXT}")
        component_file if component_file.exist?
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
