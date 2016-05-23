require 'inflecto'

module Dry
  module Component
    def self.Loader(input, namespace=nil)
      Loader.new(Loader.identifier(input), Loader.path(input), namespace)
    end

    class Loader
      IDENTIFIER_SEPARATOR = '.'.freeze
      PATH_SEPARATOR = '/'.freeze

      attr_reader :identifier, :path, :file

      def self.identifier(input)
        input.to_s.gsub(PATH_SEPARATOR, IDENTIFIER_SEPARATOR)
      end

      def self.path(input)
        input.to_s.gsub(IDENTIFIER_SEPARATOR, PATH_SEPARATOR)
      end

      def initialize(identifier, path, namespace)
        @namespace = namespace
        @identifier = identifier
        @path = path
        @file = "#{path}.rb"
      end

      def namespaces
        identifier.split(IDENTIFIER_SEPARATOR).map(&:to_sym)
      end

      def name
        [@namespace, Inflecto.camelize(path)].compact.join('::')
      end

      def constant
        Inflecto.constantize(name)
      end

      def instance(*args)
        constant.new(*args)
      end
    end
  end
end
