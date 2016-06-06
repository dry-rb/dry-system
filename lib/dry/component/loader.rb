require 'inflecto'

module Dry
  module Component
    class Loader
      IDENTIFIER_SEPARATOR = '.'.freeze
      PATH_SEPARATOR = '/'.freeze

      attr_reader :identifier, :path, :file

      def initialize(input)
        @identifier = input.to_s.gsub(PATH_SEPARATOR, IDENTIFIER_SEPARATOR)
        @path = input.to_s.gsub(IDENTIFIER_SEPARATOR, PATH_SEPARATOR)
        @file = "#{path}.rb"
      end

      def namespaces
        identifier.split(IDENTIFIER_SEPARATOR).map(&:to_sym)
      end

      def constant
        Inflecto.constantize(name)
      end

      def instance(*args)
        constant.new(*args)
      end

      private

      def name
        Inflecto.camelize(path)
      end
    end
  end
end
