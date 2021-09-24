# frozen_string_literal: true

require "concurrent/map"
require "dry/system/errors"
require_relative "namespace"

module Dry
  module System
    module Config
      class Namespaces
        attr_reader :namespaces

        # @api private
        def initialize
          @namespaces = Concurrent::Map.new
        end

        # @api private
        def initialize_copy(source)
          super
          @namespaces = source.namespaces.dup
        end

        def add(path, identifier: nil, const: path)
          raise NamespaceAlreadyAddedError, path  if namespaces.key?(path)

          namespaces[path] = Namespace.new(
            path: path,
            identifier_namespace: identifier,
            const_namespace: const
          )
        end

        def root(identifier: nil, const: identifier)
          add(Namespace::ROOT_PATH, identifier: identifier, const: const)
        end

        def empty?
          namespaces.empty?
        end

        # TODO: document why we set up a default root ns
        def to_a
          namespaces.values.tap do |arr|
            arr << Namespace.default_root unless arr.any?(&:root?)
          end
        end

        def each(&block)
          to_a.each(&block)
        end
      end
    end
  end
end
