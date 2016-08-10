module Dry
  module System
    FileNotFoundError = Class.new(StandardError) do
      def initialize(component)
        super("could not resolve require file for #{component.identifier}")
      end
    end

    ComponentLoadError = Class.new(StandardError) do
      def initialize(component)
        super("could not load component #{component.inspect}")
      end
    end

    InvalidNamespaceError = Class.new(StandardError) do
      def initialize(ns)
        super("Namespace #{ns} cannot include a separator")
      end
    end

    InvalidComponentError = Class.new(ArgumentError) do
      def initialize(name, reason = nil)
        super(
          "Tried to create an invalid #{name.inspect} component - #{reason}"
        )
      end
    end

    InvalidComponentIdentifierError = Class.new(ArgumentError) do
      def initialize(name)
        super(
          "component identifier +#{name}+ is invalid or boot file is missing"
        )
      end
    end

    InvalidComponentIdentifierTypeError = Class.new(ArgumentError) do
      def initialize(name)
        super("component identifier #{name.inspect} must be a symbol")
      end
    end
  end
end
