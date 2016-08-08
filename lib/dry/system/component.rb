require 'inflecto'

module Dry
  module System
    class Component
      attr_reader :loader
      attr_reader :identifier, :path, :file

      def initialize(loader, input)
        @loader = loader

        @identifier = input.to_s.gsub(loader.path_separator, loader.namespace_separator)

        if loader.default_namespace
          re = /^#{Regexp.escape(loader.default_namespace)}#{Regexp.escape(loader.namespace_separator)}/
          @identifier = @identifier.sub(re, '')
        end

        @path = input.to_s.gsub(loader.namespace_separator, loader.path_separator)
        @file = "#{path}.rb"
      end

      def dependency?(name)
        *deps, _ = namespaces
        (deps & name.split(loader.namespace_separator).map(&:to_sym)).size > 0
      end

      def root_key
        namespaces.first
      end

      def namespaces
        identifier.split(loader.namespace_separator).map(&:to_sym)
      end

      def instance(*args)
        if constant.respond_to?(:instance) && !constant.respond_to?(:new)
          constant.instance(*args) # a singleton
        else
          constant.new(*args)
        end
      end

      def constant
        Inflecto.constantize(constant_name)
      end

      private

      def constant_name
        Inflecto.camelize(path)
      end
    end
  end
end
