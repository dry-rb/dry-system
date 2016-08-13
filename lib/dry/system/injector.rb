require "dry-auto_inject"

module Dry
  module System
    class Injector < BasicObject
      # @api private
      attr_reader :container

      # @api private
      attr_reader :options

      # @api private
      attr_reader :injector

      # @api private
      def initialize(container, options: {}, strategy: :default)
        @container = container
        @options = options
        @injector = ::Dry::AutoInject(container, options).__send__(strategy)
      end

      # @api public
      def [](*deps)
        load_components(*deps)
        injector[*deps]
      end

      private

      def method_missing(name, *args, &block)
        ::Dry::System::Injector.new(container, options: options, strategy: name)
      end

      def load_components(*keys, **aliases)
        (keys + aliases.values).each do |key|
          container.load_component(key)
        end
      end
    end
  end
end
