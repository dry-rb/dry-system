# frozen_string_literal: true

require 'concurrent/map'

require 'dry/system/settings'

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

      attr_reader :opts

      # @api private
      def self.new(container, opts = {}, &block)
        cache.fetch_or_store([container, opts, block].hash) do
          super
        end
      end

      # @api private
      def self.cache
        @cache ||= ::Concurrent::Map.new
      end

      # @api private
      def initialize(container, opts, &block)
        @container = container
        @settings = nil
        @statuses = []
        @triggers = {}
        @opts = opts
        instance_exec(target, &block)
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
      def settings(&block)
        component.settings(&block)
      end

      # @api private
      def configure(&block)
        component.configure(&block)
      end

      # @api private
      def config
        component.config
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
          target.start(name)
        end
      end

      # @api private
      def register(*args, &block)
        container.register(*args, &block)
      end

      # @api private
      def component
        opts[:component]
      end

      # @api private
      def target
        component.container
      end

      private

      # @api private
      def trigger!(name, &block)
        if triggers.key?(name)
          triggers[name].(target)
        elsif block
          triggers[name] = block
        end
      end

      # @api private
      def method_missing(meth, *args, &block)
        if target.key?(meth)
          target[meth]
        elsif container.key?(meth)
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
