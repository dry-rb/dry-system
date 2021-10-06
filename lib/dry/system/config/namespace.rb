# frozen_string_literal: true

require "dry/core/equalizer"

module Dry
  module System
    module Config
      # A configured namespace for a component dir
      #
      # Namespaces consist of three elements:
      #
      # - The `path` within the component dir to which its namespace rules should apply.
      # - A `key_namespace`, which determines the leading part of the key used to register
      #   each component in the container.
      # - A `const_namespace`, which is the Ruby namespace expected to contain the class
      #   constants defined within each component's source file. This value is expected to
      #   be an "underscored" string, intended to be run through the configured inflector
      #   to be converted into a real constant (e.g. `"foo_bar/baz"` will become
      #   `FooBar::Baz`)
      #
      # Namespaces are added and configured for a component dir via {Namespaces#add}.
      #
      # @see Namespaces#add
      #
      # @api private
      class Namespace
        ROOT_PATH = nil

        include Dry::Equalizer(:path, :key_namespace, :const_namespace)

        attr_reader :path

        attr_reader :key_namespace

        attr_reader :const_namespace

        # Returns a namespace configured to serve as the default root namespace for a
        # component dir, ensuring that all code within the dir can be loaded, regardless
        # of any other explictly configured namespaces
        #
        # @return [Namespace] the root namespace
        #
        # @api private
        def self.default_root
          new(
            path: ROOT_PATH,
            key_namespace: nil,
            const_namespace: nil
          )
        end

        def initialize(path:, key_namespace:, const_namespace:)
          @path = path
          @key_namespace = key_namespace
          @const_namespace = const_namespace
        end

        def root?
          path == ROOT_PATH
        end

        def path?
          !root?
        end

        def default_key_namespace?
          key_namespace == path
        end
      end
    end
  end
end
