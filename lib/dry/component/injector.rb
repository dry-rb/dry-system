require "dry-auto_inject"

module Dry
  module Component
    class Injector
      class Strategy
        # @api private
        attr_reader :container

        # @api private
        attr_reader :injector

        # @api private
        def initialize(container, type)
          @container = container
          @injector = if type == :args
            Dry::AutoInject(container)
          else
            Dry::AutoInject(container).send(type)
          end
        end

        # @api public
        def [](*deps)
          load_components(*deps)
          injector[*deps]
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

      # @api private
      attr_reader :container

      # @api private
      def initialize(container)
        @container = container
      end

      # @api public
      def [](*deps)
        args[*deps]
      end

      # @api public
      def args
        strategies[:args]
      end

      # @api public
      def hash
        strategies[:hash]
      end

      # @api public
      def kwargs
        strategies[:kwargs]
      end

      private

      def strategies
        @strategies ||= Hash.new do |h, strategy_type|
          Strategy.new(container, strategy_type)
        end
      end
    end
  end
end
