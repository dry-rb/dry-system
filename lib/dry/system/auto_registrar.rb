require 'dry/system/constants'

module Dry
  module System
    # Default auto-registration implementation
    #
    # This is currently configured by default for every System::Container.
    # Auto-registrar objects are responsible for loading files from configured
    # auto-register paths and registering components automatically within the
    # container.
    #
    # @api private
    class AutoRegistrar
      attr_reader :container

      attr_reader :config

      def initialize(container)
        @container = container
        @config = container.config
      end

      # @api private
      def finalize!
        Array(config.auto_register).each { |dir| call(dir) }
      end

      # @api private
      def call(dir, &block)
        components(dir).each do |component|
          container.require_component(component) do
            if block
              register(component.identifier, yield(component))
            else
              register(component.identifier) { component.instance }
            end
          end
        end
      end

      private

      # @api private
      def components(dir)
        paths(dir).
          map { |path| component(path) }.
          reject { |component| key?(component.identifier) }
      end

      # @api private
      def paths(dir)
        dir_root = root.join(dir.to_s.split('/')[0])

        Dir["#{root}/#{dir}/**/*.rb"].map { |path|
          path.to_s.sub("#{dir_root}/", '').sub(RB_EXT, EMPTY_STRING)
        }
      end

      # @api private
      def component(path)
        container.component(path)
      end

      # @api private
      def root
        container.root
      end

      # @api private
      def key?(name)
        container.key?(name)
      end

      # @api private
      def register(*args, &block)
        container.register(*args, &block)
      end
    end
  end
end
