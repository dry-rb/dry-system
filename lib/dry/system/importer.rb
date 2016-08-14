module Dry
  module System
    class Importer
      attr_reader :container

      attr_reader :separator

      attr_reader :registry

      def initialize(container)
        @container = container
        @separator = container.config.namespace_separator
        @registry = {}
      end

      def finalize!
        registry.each do |name, container|
          call(name, container.finalize!)
        end
      end

      def [](name)
        registry.fetch(name)
      end

      def key?(name)
        registry.key?(name)
      end

      def call(ns, other)
        container.merge(other, namespace: ns)
      end

      def register(other)
        registry.update(other)
      end
    end
  end
end
