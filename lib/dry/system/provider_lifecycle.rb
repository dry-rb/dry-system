# frozen_string_literal: true

require "dry/core/deprecations"
require "dry/system/settings"

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
    class ProviderLifecycle < BasicObject
      extend ::Dry::Core::Deprecations["Dry::System::Lifecycle"]

      attr_reader :provider

      attr_reader :container

      attr_reader :statuses

      attr_reader :triggers

      # @api private
      def initialize(provider:, container:, &block)
        @provider = provider
        @container = container
        @settings = nil
        @statuses = []
        @triggers = {}
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
          target.start(name)
        end
      end

      # @api private
      def register(*args, &block)
        container.register(*args, &block)
      end

      # @api private
      def target
        provider.target_container
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
      def method_missing(name, *args, &block)
        if target.registered?(name)
          target[name]
        elsif container.key?(name)
          container[name]
        elsif ::Kernel.respond_to?(name)
          ::Kernel.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, include_all = false)
        target.registered?(name) || container.key?(name) || ::Kernel.respond_to?(name) || super
      end
    end
  end
end
