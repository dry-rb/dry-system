require 'dry/system/component'

module Dry
  module System
    class Loader
      PATH_SEPARATOR = '/'.freeze

      attr_reader :default_namespace
      attr_reader :namespace_separator
      attr_reader :path_separator

      def initialize(config)
        @default_namespace = config.default_namespace
        @namespace_separator = config.namespace_separator
        @path_separator = PATH_SEPARATOR
      end

      def load(path)
        Component.new(self, path)
      end
    end
  end
end
