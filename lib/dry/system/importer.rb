# frozen_string_literal: true

require "dry/container"

module Dry
  module System
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

      attr_reader :registry

      # @api private
      def initialize(container)
        @container = container
        @registry = {}
      end

      # @api private
      def finalize!
        registry.each do |namespace, container|
          call(namespace, container)
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

      # @api private
      def call(namespace, other)
        if other.config.exports.nil?
          container.merge(other.finalize!, namespace: namespace)
        else
          # This has the work to generate the import container within the importer.
          # Another approach could be to have that on the containers themselves, e.g.
          # `some_container.export_container` or similar
          import_container = other.config.exports.each_with_object(Dry::Container.new) { |key, ic|
            ic.register(key, other[key])
          }
          container.merge(import_container, namespace: namespace)
        end
      end

      def import_component(namespace, other_container, key)
        # TODO: really need methods exposing this logic
        return if !other_container.config.exports.nil? && other_container.config.exports.empty?
        return if Array(other_container.config.exports).any? && !other_container.config.exports.include?(key)

        value = other_container[key]

        # TODO: better way of constructing key?
        container.register("#{namespace}.#{key}", value)
      end

      # @api private
      def register(other)
        registry.update(other)
      end
    end
  end
end
