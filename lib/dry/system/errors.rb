# frozen_string_literal: true

module Dry
  module System
    # Error raised when a component dir is added to configuration more than once
    #
    # @api public
    ComponentDirAlreadyAddedError = Class.new(StandardError) do
      def initialize(dir)
        super("Component directory #{dir.inspect} already added")
      end
    end

    NoComponentDirError = Class.new(StandardError) do
      def initialize(path)
        super("No component dir configured with path '#{path}'")
      end
    end

    # Error raised when a namespace for a component dir is added to configuration more
    # than once
    NamespaceAlreadyAddedError = Class.new(StandardError) do
      def initialize(path)
        path_label = path ? "path #{path.inspect}" : "root path"

        super("Namespace for #{path_label} already added")
      end
    end

    # Error raised when booter file do not match with register component
    #
    # @api public
    ComponentFileMismatchError = Class.new(StandardError) do
      def initialize(component)
        super(<<-STR)
          Bootable component '#{component.name}' not found
        STR
      end
    end

    # Error raised when resolved component couldn't be loaded
    #
    # @api public
    InvalidComponentError = Class.new(ArgumentError) do
      def initialize(name, reason = nil)
        super(
          "Tried to create an invalid #{name.inspect} component - #{reason}"
        )
      end
    end

    # Error raised when component's name is not valid
    #
    # @api public
    InvalidComponentNameError = Class.new(ArgumentError) do
      def initialize(name)
        super(
          "component +#{name}+ is invalid or boot file is missing"
        )
      end
    end

    # Error raised when trying to stop a component that hasn't started yet
    #
    # @api public
    ComponentNotStartedError = Class.new(StandardError) do
      def initialize(component_name)
        super("component +#{component_name}+ has not been started")
      end
    end

    # Error raised when trying to use a plugin that does not exist.
    #
    # @api public
    PluginNotFoundError = Class.new(StandardError) do
      def initialize(plugin_name)
        super("Plugin #{plugin_name.inspect} does not exist")
      end
    end

    # Error raised when a configured component directory could not be found
    #
    # @api public
    ComponentDirNotFoundError = Class.new(StandardError) do
      def initialize(dir)
        super("Component dir '#{dir}' not found")
      end
    end

    DuplicatedComponentKeyError = Class.new(ArgumentError)

    InvalidSettingsError = Class.new(ArgumentError) do
      # @api private
      def initialize(attributes)
        message = <<~STR
          Could not initialize settings. The following settings were invalid:

          #{attributes_errors(attributes).join("\n")}
        STR
        super(message)
      end

      private

      def attributes_errors(attributes)
        attributes.map { |key, error| "#{key.name}: #{error}" }
      end
    end

    # Exception raise when a plugin dependency failed to load
    #
    # @api public
    PluginDependencyMissing = Class.new(StandardError) do
      # @api private
      def initialize(plugin, message, gem = nil)
        details = gem ? "#{message} - add #{gem} to your Gemfile" : message
        super("dry-system plugin #{plugin.inspect} failed to load its dependencies: #{details}")
      end
    end
  end
end
