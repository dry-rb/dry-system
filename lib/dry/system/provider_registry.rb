# frozen_string_literal: true

module Dry
  module System
    class ProviderRegistry
      include Enumerable

      attr_reader :items

      def initialize
        @items = []
      end

      def each(&block)
        items.each(&block)
      end

      def register(identifier, options)
        items << Provider.new(identifier, options)
      end

      def [](identifier)
        detect { |provider| provider.identifier == identifier }
      end
    end
  end
end
