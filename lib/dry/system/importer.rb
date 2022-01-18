# frozen_string_literal: true

require "dry/container"
require_relative "constants"

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
      # @api private
      class Item
        attr_reader :namespace, :container, :import_keys

        def initialize(namespace:, container:, import_keys:)
          @namespace = namespace
          @container = container
          @import_keys = import_keys
        end
      end

      attr_reader :container

      attr_reader :registry

      # @api private
      def initialize(container)
        @container = container
        @registry = {}
      end

      def register(container:, namespace:, keys: Undefined)
        registry[namespace] = Item.new(namespace: namespace, container: container, import_keys: keys)
      end

      # @api private
      def [](name)
        registry.fetch(name)
      end

      # @api private
      def key?(name)
        registry.key?(name)
      end
      alias_method :namespace?, :key?

      # @api private
      def finalize!
        registry.each_key { import(_1) }
        self
      end

      # @api private
      def import(namespace, keys: Undefined)
        item = self[namespace]
        keys = Undefined.default(keys, item.import_keys)

        if keys
          import_keys(item.container, namespace, keys_to_import(keys, item))
        else
          import_all(item.container, namespace)
        end

        self
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
          import_container = keys.each_with_object(Dry::Container.new) { |key, ic|
            # In this case, where keys have been provided, we should raise an error if other.key?(key) is nil
            ic.register(key, other[key]) if other.key?(key)
          }
          container.merge(import_container, namespace: namespace)
        end

        self
      end

      def keys_to_import(keys, item)
        keys
          .then { (arr = item.import_keys) ? _1 & arr : _1 }
          .then { (arr = item.container.config.exports) ? _1 & arr : _1 }
      end
    end
  end
end
