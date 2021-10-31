# frozen_string_literal: true

require "dry/system/errors"
require_relative "namespace"

module Dry
  module System
    module Config
      # The configured namespaces for a ComponentDir
      #
      # @see Config::ComponentDir#namespaces
      #
      # @api private
      class Namespaces
        # @api private
        attr_reader :namespaces

        # @api private
        def initialize
          @namespaces = {}
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
        #   namespaces.add "admin", key: nil
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
        #   namespaces.add "bananas", key: "desserts", const: "eat_me/now"
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
        def add(path, key: path, const: path)
          raise NamespaceAlreadyAddedError, path if namespaces.key?(path)

          namespaces[path] = Namespace.new(path: path, key: key, const: const)
        end

        # rubocop:enable Layout/LineLength

        # Adds a root component dir namespace
        #
        # @see #add
        #
        # @api public
        def root(key: nil, const: nil)
          add(Namespace::ROOT_PATH, key: key, const: const)
        end

        # @api private
        def empty?
          namespaces.empty?
        end

        # Returns the configured namespaces as an array
        #
        # This adds a root namespace to the end of the array if one was not configured
        # manually. This fallback ensures that all components in the component dir can be
        # loaded.
        #
        # @return [Array<Namespace>] the namespaces
        #
        # @api private
        def to_a
          namespaces.values.tap do |arr|
            arr << Namespace.default_root unless arr.any?(&:root?)
          end
        end

        # @api private
        def each(&block)
          to_a.each(&block)
        end
      end
    end
  end
end
