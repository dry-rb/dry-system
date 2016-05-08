require "dry-auto_inject"

module Dry
  module Component
    class Injector
      attr_reader :container
      attr_reader :type
      attr_reader :injector

      # @api private
      def initialize(container)
        @container = container
      end

      # @api private
      def injectors
        @injectors ||= Hash.new do |h, injector_type|
          h[injector_type] = if injector_type == :args
            Dry::AutoInject(container)
          else
            Dry::AutoInject(container).send(injector_type)
          end
        end
      end

      # @api public
      def args(*deps)
        load_components(*deps)
        injectors[:args][*deps]
      end
      alias_method :[], :args

      # @api public
      def hash(*deps)
        load_components(*deps)
        injectors[:hash][*deps]
      end

      # @api public
      def kwargs(*deps)
        load_components(*deps)
        injectors[:kwargs][*deps]
      end

      private

      def load_components(*components)
        components = components.dup
        aliases = components.last.is_a?(Hash) ? components.pop : {}

        (components + aliases.values).each do |key|
          container.load_component(key) unless container.key?(key)
        end
      end
    end
  end
end
