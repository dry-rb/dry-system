require 'concurrent/map'

module Dry
  module System
    # Lifecycle booting DSL
    #
    # Lifecycle objects are used in the boot files where you can register custom
    # init/start/stop triggers
    #
    # @see [Container.finalize]
    #
    # @api private
    class Lifecycle < BasicObject
      attr_reader :container

      attr_reader :init

      attr_reader :start

      attr_reader :stop

      attr_reader :statuses

      attr_reader :triggers

      # @api private
      def self.new(container, &block)
        cache.fetch_or_store([container, block].hash) do
          super
        end
      end

      # @api private
      def self.cache
        @cache ||= ::Concurrent::Map.new
      end

      # @api private
      def initialize(container, &block)
        @container = container
        @statuses = []
        @triggers = {}
        instance_exec(container, &block)
      end

      # @api private
      def call(*triggers)
        triggers.each do |trigger|
          unless statuses.include?(trigger)
            __send__(trigger)
            statuses << trigger
          end
        end
      end

      # @api private
      def init(&block)
        trigger!(:init, &block)
      end

      # @api private
      def start(&block)
        trigger!(:start, &block)
      end

      # @api private
      def stop(&block)
        trigger!(:stop, &block)
      end

      # @api private
      def use(*names)
        names.each do |name|
          container.boot!(name)
        end
      end

      # @api private
      def register(*args, &block)
        container.register(*args, &block)
      end

      private

      # @api private
      def trigger!(name, &block)
        if triggers.key?(name)
          triggers[name].()
        elsif block
          triggers[name] = block
        end
      end

      # @api private
      def method_missing(meth, *args, &block)
        if container.key?(meth)
          container[meth]
        elsif ::Kernel.respond_to?(meth)
          ::Kernel.public_send(meth, *args, &block)
        else
          super
        end
      end
    end
  end
end
