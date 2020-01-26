# frozen_string_literal: true

module Dry
  module System
    # Error raised when the container tries to load a component with missing
    # file
    #
    # @api public
    FileNotFoundError = Class.new(StandardError) do
      def initialize(component)
        super("could not resolve require file for #{component.identifier}")
      end
    end

    # Error raised when booter file do not match with register component
    #
    # @api public
    ComponentFileMismatchError = Class.new(StandardError) do
      def initialize(component)
        path = component.boot_path
        files = component.container_boot_files

        super(<<-STR)
          Boot file for component #{component.identifier.inspect} not found.
          Container boot files under #{path}: #{files.inspect}")
        STR
      end
    end

    # Error raised when a resolved component couldn't be found
    #
    # @api public
    ComponentLoadError = Class.new(StandardError) do
      def initialize(component)
        super("could not load component #{component.inspect}")
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

    # Error raised when component's identifier is not valid
    #
    # @api public
    InvalidComponentIdentifierError = Class.new(ArgumentError) do
      def initialize(name)
        super(
          "component identifier +#{name}+ is invalid or boot file is missing"
        )
      end
    end

    # Error raised when component's identifier for booting is not a symbol
    #
    # @api public
    InvalidComponentIdentifierTypeError = Class.new(ArgumentError) do
      def initialize(name)
        super("component identifier #{name.inspect} must be a symbol")
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

    ComponentsDirMissing = Class.new(StandardError)
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
