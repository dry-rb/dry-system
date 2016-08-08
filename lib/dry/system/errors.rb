module Dry
  module System
    FileNotFoundError = Class.new(StandardError) do
      def initialize(component)
        super("could not resolve require file for #{component.identifier}")
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
