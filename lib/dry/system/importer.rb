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
        registry.each do |namespace, opts|
          container = opts.fetch(:container)
          keys = opts.fetch(:keys)

          call(other: container, namespace: namespace, keys: keys)
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

      # TODO: I have a feeling that "call" isn't the best name for this anymore
      #
      # @api private
      def call(other:, namespace:, keys: nil)
        if keys
          import_keys(other, namespace, keys)
        else
          import_all(other, namespace)
        end

        self
      end

      def import_component(namespace, key)
        opts = self[namespace]
        other_container = opts.fetch(:container)
        keys = opts.fetch(:keys)

        # TODO: really need methods exposing this logic
        return self if !other_container.config.exports.nil? && other_container.config.exports.empty?
        return self if Array(other_container.config.exports).any? && !other_container.config.exports.include?(key)
        return self if keys && !keys.include?(key) # TODO: this should raise error?

        if other_container.key?(key)
          # TODO: better way of constructing key?
          container.register("#{namespace}.#{key}", other_container[key])
        end

        # TODO: return self?
        self
      end

      def register(container:, namespace:, keys: Undefined)
        # TODO: maybe we want a better data structure for this
        registry[namespace] = {container: container, keys: keys}
      end

      # @api private
      def old_register(other)
        registry.update(other)
      end

      private

      def import_all(other, namespace)
        if other.config.exports.nil?
          container.merge(other.finalize!, namespace: namespace)
        else
          import_container = other.config.exports.each_with_object(Dry::Container.new) { |key, ic|
            # TODO: this should be made from the container _items_, not by re-registering
            # and re-resolving
            ic.register(key, other[key]) if other.key?(key)
          }
          container.merge(import_container, namespace: namespace)
        end

        self
      end

      def import_keys(other, namespace, keys)
        if other.config.exports.nil?
          import_container = keys.each_with_object(Dry::Container.new) { |key, ic|
            ic.register(key, other[key]) if other.key?(key)
          }

          container.merge(import_container, namespace: namespace)
        else
          import_container = keys_to_import(keys, other.config.exports).each_with_object(Dry::Container.new) { |key, ic|
            # In this case, where keys have been provided, we should raise an error if other.key?(key) is nil
            ic.register(key, other[key]) if other.key?(key)
          }
          container.merge(import_container, namespace: namespace)
        end

        self
      end

      def keys_to_import(keys, export_keys)
        # TODO: raise error if `keys` includes keys that are not in `export_keys`
        keys & export_keys
      end

    end
  end
end
