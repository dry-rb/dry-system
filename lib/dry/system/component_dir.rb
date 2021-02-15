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

      # @!attribute [r] root
      #   @return [Pathname] the configured root directory
      #   @see Dry::System::Container#root
      #   @api private
      attr_reader :root

      # @api private
      def initialize(config:, root:)
        @root = Pathname(root)
        @config = config
      end

      # Returns the full path of the component directory
      #
      # @return [Pathname]
      # @api private
      def full_path
        root.join(path)
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
