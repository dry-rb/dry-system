module Dry
  module System
    DuplicatedComponentKeyError = Class.new(ArgumentError)
    InvalidSettingsError = Class.new(ArgumentError) do
      # @api private
      def initialize(attributes)
        message = <<~EOF
          Could not initialize settings. The following settings were invalid:

          #{attributes_errors(attributes).join("\n")}
        EOF
        super(message)
      end

      private

      def attributes_errors(attributes)
        attributes.map { |key, error| "#{key}: #{error}" }
      end
    end

    # Exception raise when a plugin dependency failed to load
    #
    # @api public
    PluginDependencyMissing = Class.new(StandardError) do
      # @api private
      def initialize(plugin, message)
        super("dry-system plugin #{plugin.inspect} failed to load its dependencies: #{message}")
      end
    end

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
        super("Boot file for component #{component.identifier.inspect} not found. Container boot files under #{component.boot_path}: #{component.container_boot_files.inspect}")
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

    InvalidPluginError = Class.new(ArgumentError) do
      def initialize(plugin)
        super("plugin +#{plugin.inspect} is not a valid Dry::System plugin.")
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
  end
end
