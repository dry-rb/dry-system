require 'concurrent/map'

module Dry
  module System
    class Lifecycle < BasicObject
      attr_reader :container

      attr_reader :init

      attr_reader :start

      attr_reader :stop

      attr_reader :statuses

      attr_reader :triggers

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
        @triggers = {}
        instance_exec(container, &block)
      end

      def call(*triggers)
        triggers.each do |trigger|
          unless statuses.include?(trigger)
            __send__(trigger)
            statuses << trigger
          end
        end
      end

      def init(&block)
        trigger!(:init, &block)
      end

      def start(&block)
        trigger!(:start, &block)
      end

      def stop(&block)
        trigger!(:stop, &block)
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

      def trigger!(name, &block)
        if triggers.key?(name)
          triggers[name].()
        elsif block
          triggers[name] = block
        end
      end

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
