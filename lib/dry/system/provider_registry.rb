module Dry
  module System
    class ProviderRegistry
      include Enumerable

      attr_reader :providers

      def initialize
        @providers = []
      end

      def each(&block)
        providers.each(&block)
      end

      def register(identifier, options)
        providers << Provider.new(identifier, options)
      end

      def [](identifier)
        detect { |provider| provider.identifier == identifier }
      end
    end
  end
end
