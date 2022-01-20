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

      # @api private
      def register(namespace:, container:, keys: nil)
        registry[namespace] = Item.new(
          namespace: namespace,
          container: container,
          import_keys: keys
        )
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

      def keys_to_import(keys, item)
        keys
          .then { (arr = item.import_keys) ? _1 & arr : _1 }
          .then { (arr = item.container.exports) ? _1 & arr : _1 }
      end

      def import_keys(other, namespace, keys)
        container.merge(build_merge_container(other, keys, force = !!other.exports), namespace: namespace)
      end

      def import_all(other, namespace)
        if other.exports.nil?
          container.merge(build_merge_container(other.finalize!, other.keys, force = false), namespace: namespace)
        else
          container.merge(build_merge_container(other, other.exports, force = !!other.exports), namespace: namespace)
        end
      end

      def build_merge_container(other, keys, force = false)
        keys.each_with_object(Dry::Container.new) { |key, ic|
          next unless other.key?(key)

          # Access the other container's items directly so that we can preserve all their
          # options when we merge them with the target container (e.g. if a component in
          # the provider container was registered with a block, we want block registration
          # behavior to be exhibited when later resolving that component from the target
          # container).
          item = other._container[key]

          next if !force && item.options.key?(:export) && !item.options[:export]

          if item.callable?
            ic.register(key, **item.options, export: false, &item.item)
          else
            ic.register(key, item.item, **item.options, export: false)
          end
        }
      end
    end
  end
end
