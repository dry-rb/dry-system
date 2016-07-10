require "dry-auto_inject"

module Dry
  module Component
    class Injector < BasicObject
      # @api private
      attr_reader :container

      # @api private
      attr_reader :injector

      # @api private
      def initialize(container, strategy: nil)
        @container = container
        @injector =
          if strategy
            ::Dry::AutoInject(container).send(strategy)
          else
            ::Dry::AutoInject(container)
          end
      end

      # @api public
      def [](*deps)
        load_components(*deps)
        injector[*deps]
      end

      def method_missing(name, *args, &block)
        ::Dry::Component::Injector.new(container, strategy: name)
      end

      def respond_to_missing?(name, _include_private = false)
        injector.respond_to?(name)
      end

      private

      def load_components(*components)
        components = components.dup
        aliases = components.last.is_a?(::Hash) ? components.pop : {}

        (components + aliases.values).each do |key|
          container.load_component(key) unless container.key?(key)
        end
      end
    end
  end
end
