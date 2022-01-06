# frozen_string_literal: true

require "dry/core/deprecations"

module Dry
  module System
    extend Dry::Core::Deprecations["dry-system"]

    # Error raised when a component dir is added to configuration more than once
    #
    # @api public
    ComponentDirAlreadyAddedError = Class.new(StandardError) do
      def initialize(dir)
        super("Component directory #{dir.inspect} already added")
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

    # Error raised when a namespace for a component dir is added to configuration more
    # than once
    #
    # @api public
    NamespaceAlreadyAddedError = Class.new(StandardError) do
      def initialize(path)
        path_label = path ? "path #{path.inspect}" : "root path"

        super("Namespace for #{path_label} already added")
      end
    end

    # Error raised when attempting to register provider using a name that has already been
    # registered
    #
    # @api public
    ProviderAlreadyRegisteredError = Class.new(ArgumentError) do
      def initialize(provider_name)
        super("Provider #{provider_name.inspect} has already been registered")
      end
    end
    DuplicatedComponentKeyError = ProviderAlreadyRegisteredError
    deprecate_constant :DuplicatedComponentKeyError

    # Error raised when a named provider could not be found
    #
    # @api public
    ProviderNotFoundError = Class.new(ArgumentError) do
      def initialize(name)
        super("Provider #{name.inspect} not found")
      end
    end
    InvalidComponentError = ProviderNotFoundError
    deprecate_constant :InvalidComponentError

    # Error raised when trying to stop a provider that hasn't started yet
    #
    # @api public
    ProviderNotStartedError = Class.new(StandardError) do
      def initialize(provider_name)
        super("Provider #{provider_name.inspect} has not been started")
      end
    end
    ComponentNotStartedError = ProviderNotStartedError
    deprecate_constant :ComponentNotStartedError

    # Error raised when trying to use a plugin that does not exist.
    #
    # @api public
    PluginNotFoundError = Class.new(StandardError) do
      def initialize(plugin_name)
        super("Plugin #{plugin_name.inspect} does not exist")
      end
    end

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
