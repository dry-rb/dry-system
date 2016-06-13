require "dry-auto_inject"

module Dry
  module Component
    class Injector
      # @api private
      attr_reader :container

      # @api private
      attr_reader :injector

      # @api private
      def initialize(container, strategy: nil, strategies_cache: nil)
        @container = container
        @strategies = strategies_cache
        @injector =
          if strategy
            Dry::AutoInject(container).send(strategy)
          else
            Dry::AutoInject(container)
          end
      end

      # @api public
      def [](*deps)
        load_components(*deps)
        injector[*deps]
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

      def load_components(*components)
        components = components.dup
        aliases = components.last.is_a?(Hash) ? components.pop : {}

        (components + aliases.values).each do |key|
          container.load_component(key) unless container.key?(key)
        end
      end

      def strategies
        @strategies ||= Hash.new do |cache, strategy|
          cache[strategy] = self.class.new(container, strategy: strategy, strategies_cache: cache)
        end
      end
    end
  end
end
