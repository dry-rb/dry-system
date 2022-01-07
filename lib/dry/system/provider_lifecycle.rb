# frozen_string_literal: true

require "dry/core/deprecations"

module Dry
  module System
    # Lifecycle booting DSL
    #
    # Lifecycle objects are used in the boot files where you can register custom
    # prepare/start/stop triggers
    #
    # @see [Container.finalize]
    #
    # @api private
    # TODO: Make this not a BasicObject - tbh it's a pain in the butt to debug against
    class ProviderLifecycle < BasicObject
      extend ::Dry::Core::Deprecations["Dry::System::Lifecycle"]

      attr_reader :provider

      attr_reader :statuses

      attr_reader :triggers

      # @api private
      def initialize(provider:, &lifecycle_block)
        @provider = provider
        @statuses = []
        @triggers = {}
        instance_exec(target_container, &lifecycle_block)
      end

      # @api private
      def call(*triggers)
        triggers.each do |trigger|
          unless statuses.include?(trigger)
            # TODO: make the triggers explicit, we shouldn't just allow arbitrary methods to run here
            __send__(trigger)
            statuses << trigger
          end
        end
      end

      # @api private
      def settings(&block)
        provider.settings(&block)
      end

      # @api private
      def configure(&block)
        provider.configure(&block)
      end

      # @api private
      def config
        provider.config
      end

      # @api private
      def prepare(&block)
        trigger!(:prepare, &block)
      end
      deprecate :init, :prepare

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
          target_container.start(name)
        end
      end

      # @api private
      def register(*args, &block)
        container.register(*args, &block)
      end

      private

      def container
        provider.container
      end

      def target_container
        provider.target_container
      end

      # @api private
      def trigger!(name, &block)
        if triggers.key?(name)
          triggers[name].(target_container)
        elsif block
          triggers[name] = block
        end
      end

      # @api private
      def method_missing(name, *args, &block)
        if target_container.registered?(name)
          target_container[name]
        elsif container.key?(name)
          container[name]
        elsif ::Kernel.respond_to?(name)
          ::Kernel.public_send(name, *args, &block)
        else
          # ::Kernel.byebug
          super
        end
      end

      def respond_to_missing?(name, include_all = false)
        target_container.registered?(name) || container.key?(name) || ::Kernel.respond_to?(name) || super
      end
    end
  end
end
