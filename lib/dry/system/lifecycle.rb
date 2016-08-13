require 'concurrent/map'

module Dry
  module System
    class Lifecycle < BasicObject
      attr_reader :container

      attr_reader :start

      attr_reader :stop

      attr_reader :runtime

      attr_reader :statuses

      def self.new(container, &block)
        cache.fetch_or_store([container, block].hash) do
          super
        end
      end

      def self.cache
        @cache ||= ::Concurrent::Map.new
      end

      def initialize(container, &block)
        @container = container
        @statuses = []
        instance_exec(container, &block)
      end

      def call(*triggers)
        triggers.each do |trigger|
          __send__(trigger) unless statuses.include?(trigger)
          statuses << trigger
        end
      end

      def start(&block)
        if @start
          @start.()
        elsif block
          @start = block
        end
      end

      def stop(&block)
        if @stop
          @stop.()
        elsif block
          @stop = block
        end
      end

      def runtime(&block)
        if @runtime
          @runtime.()
        elsif block
          @runtime = block
        end
      end

      def uses(*names)
        names.each do |name|
          container.boot!(name)
        end
      end

      def register(*args, &block)
        container.register(*args, &block)
      end

      private

      def method_missing(meth, *args, &block)
        if container.key?(meth)
          container[meth]
        elsif ::Kernel.respond_to?(meth)
          ::Kernel.public_send(meth, *args, &block)
        end
      end
    end
  end
end
