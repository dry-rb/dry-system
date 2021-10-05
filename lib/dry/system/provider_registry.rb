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

      def register(name, options)
        items << Provider.new(name, options)
      end

      def [](name)
        detect { |provider| provider.name == name }
      end
    end
  end
end
