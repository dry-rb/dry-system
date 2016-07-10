require 'inflecto'

module Dry
  module Component
    class Loader
      class Component
        attr_reader :loader
        attr_reader :identifier, :path, :file

        def initialize(loader, input)
          @loader = loader

          @identifier = input.to_s.gsub(loader.path_separator, loader.namespace_separator)
          if loader.namespace
            re = /^#{Regexp.escape(loader.namespace)}#{Regexp.escape(loader.namespace_separator)}/
            @identifier = @identifier.gsub(re, '')
          end

          @path = input.to_s.gsub(loader.namespace_separator, loader.path_separator)
          @file = "#{path}.rb"
        end

        def namespaces
          identifier.split(loader.namespace_separator).map(&:to_sym)
        end

        def constant
          Inflecto.constantize(constant_name)
        end

        def instance(*args)
          constant.new(*args)
        end

        private

        def constant_name
          Inflecto.camelize(path)
        end
      end

      PATH_SEPARATOR = '/'.freeze

      attr_reader :namespace
      attr_reader :namespace_separator
      attr_reader :path_separator

      def initialize(container)
        @namespace = container.config.namespace
        @namespace_separator = container.config.namespace_separator
        @path_separator = PATH_SEPARATOR
      end

      def load(component_path)
        Component.new(self, component_path)
      end
    end
  end
end
