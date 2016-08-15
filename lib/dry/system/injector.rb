require "dry-auto_inject"

module Dry
  module System
    # Injection mixin builder
    #
    # Injector objects are created by containers and can be used to automatically
    # define object constructors where depedencies will be injected in.
    #
    # Main purpose of this object is to provide injection along with lazy-loading
    # of components on demand. This gives us a way to load components in
    # isolation from the rest of the system.
    #
    # @see [Container.injector]
    #
    # @api public
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

      # Create injection mixin for specified dependencies
      #
      # @example
      #   require 'system/import'
      #
      #   class UserRepo
      #     include Import['persistence.db']
      #   end
      #
      # @param [Array<String>] *deps Keys under which dependencies are registered
      #
      # @return [Dry::AutoInject::Injector]
      #
      # @api public
      def [](*deps)
        load_components(*deps)
        injector[*deps]
      end

      private

      # @api private
      def method_missing(name, *args, &block)
        ::Dry::System::Injector.new(container, options: options, strategy: name)
      end

      # @api private
      def load_components(*keys, **aliases)
        (keys + aliases.values).each do |key|
          container.load_component(key)
        end
      end
    end
  end
end
