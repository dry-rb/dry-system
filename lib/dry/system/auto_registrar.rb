require 'dry/system/constants'

module Dry
  module System
    class AutoRegistrar
      attr_reader :container

      attr_reader :config

      def initialize(container)
        @container = container
        @config = container.config
      end

      def finalize!
        Array(config.auto_register).each { |dir| call(dir) }
      end

      def call(dir, &block)
        dir_root = root.join(dir.to_s.split('/')[0])

        Dir["#{root}/#{dir}/**/*.rb"].each do |path|
          path = path.to_s.sub("#{dir_root}/", '').sub(RB_EXT, EMPTY_STRING)

          component(path).tap do |component|
            next if key?(component.identifier)

            Kernel.require component.path

            if block
              register(component.identifier, yield(component))
            else
              register(component.identifier) { component.instance }
            end
          end
        end
      end

      private

      def component(path)
        container.component(path)
      end

      def root
        container.root
      end

      def key?(name)
        container.key?(name)
      end

      def register(*args, &block)
        container.register(*args, &block)
      end
    end
  end
end
