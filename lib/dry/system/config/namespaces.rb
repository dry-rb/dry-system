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

        # rubocop:disable Layout/LineLength

        # Adds a component dir namespace
        #
        # A namespace encompasses a given sub-directory of the component dir, and
        # determines (1) the leading segments of its components' registered identifiers,
        # and (2) the expected constant namespace of their class constants.
        #
        # A namespace for a path can only be added once.
        #
        # @example Adding a namespace with top-level identifiers
        #   # Components defined within admin/ (e.g. admin/my_component.rb) will be:
        #   #
        #   # - Registered with top-level identifiers ("my_component")
        #   # - Expected to have constants in `Admin`, matching the namespace's path (Admin::MyComponent)
        #
        #   namespaces.add "admin", identifier: nil
        #
        # @example Adding a namespace with top-level class constants
        #   # Components defined within adapters/ (e.g. adapters/my_adapter.rb) will be:
        #   #
        #   # - Registered with leading identifiers matching the namespace's path ("adapters.my_adapter")
        #   # - Expected to have top-level constants (::MyAdapter)
        #
        #   namespaces.add "adapters", const: nil
        #
        # @example Adding a namespace with distinct identifiers and class constants
        #   # Components defined within `bananas/` (e.g. bananas/banana_split.rb) will be:
        #   #
        #   # - Registered with the given leading identifier ("desserts.banana_split")
        #   # - Expected to have constants within the given namespace (EatMe::Now::BananaSplit)
        #
        #   namespaces.add "bananas", identifier: "desserts", const: "eat_me/now"
        #
        # @param path [String] the path to the sub-directory of source files to which this
        #   namespace should apply, relative to the component dir
        # @param identifier [String, nil] the leading namespace to apply to the registered
        #   identifiers for the components. Set `nil` for the identifiers to be top-level.
        # @param const [String, nil] the Ruby constant namespace to expect for constants
        #   defined within the components. This should be provided in underscored string
        #   form, e.g. "hello_there/world" for a Ruby constant of `HelloThere::World`. Set
        #   `nil` for the constants to be top-level.
        #
        # @return [Namespace] the added namespace
        #
        # @see Namespace
        #
        # @api public
        def add(path, identifier: path, const: path)
          raise NamespaceAlreadyAddedError, path if namespaces.key?(path)

          namespaces[path] = Namespace.new(
            path: path,
            identifier_namespace: identifier,
            const_namespace: const
          )
        end

        # rubocop:enable Layout/LineLength

        # @api public
        def root(identifier: nil, const: nil)
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
