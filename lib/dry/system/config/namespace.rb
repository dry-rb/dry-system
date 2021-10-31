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
      # - A `key`, which determines the leading part of the key used to register
      #   each component in the container.
      # - A `const`, which is the Ruby namespace expected to contain the class constants
      #   defined within each component's source file. This value is expected to be an
      #   "underscored" string, intended to be run through the configured inflector to be
      #   converted into a real constant (e.g. `"foo_bar/baz"` will become `FooBar::Baz`)
      #
      # Namespaces are added and configured for a component dir via {Namespaces#add}.
      #
      # @see Namespaces#add
      #
      # @api private
      class Namespace
        ROOT_PATH = nil

        include Dry::Equalizer(:path, :key, :const)

        attr_reader :path

        attr_reader :key

        attr_reader :const

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
            key: nil,
            const: nil
          )
        end

        def initialize(path:, key:, const:)
          @path = path
          @key = key
          @const = const
        end

        def root?
          path == ROOT_PATH
        end

        def path?
          !root?
        end

        def default_key?
          key == path
        end
      end
    end
  end
end
