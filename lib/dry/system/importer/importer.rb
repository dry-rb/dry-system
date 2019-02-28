module Dry
  module System
    module Importer
      # Default importer implementation
      #
      # This is currently configured by default for every System::Container.
      # Importer objects are responsible for importing components from one
      # container to another. This is used in cases where an application is split
      # into multiple sub-systems.
      #
      # @api private
      class Importer
        attr_reader :container

        attr_reader :separator

        attr_reader :registry

        # @api private
        def initialize(container, separator: DEFAULT_SEPARATOR)
          @container = container
          @separator = separator
          @registry = {}
        end

        # @api private
        def finalize!
          registry.each do |name, container|
            container = container.finalize! if container.respond_to?(:finalize!)
            call(name, container)
          end
          self
        end

        # @api private
        def [](name)
          registry.fetch(name)
        end

        # @api private
        def key?(name)
          registry.key?(name)
        end
        alias_method :has_key?, :key?

        # @api private
        def call(ns, other)
          container.merge(other, namespace: ns)
        end

        # @api private
        def register(other)
          registry.update(other)
        end
      end
    end
  end
end