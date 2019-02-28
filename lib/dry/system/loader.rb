require 'dry/inflector'
require 'dry-configurable'

module Dry
  module System
    # Default component loader implementation
    #
    # This class is configured by default for every System::Container. You can
    # provide your own and use it in your containers too.
    #
    # @example
    #   class MyLoader < Dry::System::Loader
    #     def call(*args)
    #       constant.build(*args)
    #     end
    #   end
    #
    #   class MyApp < Dry::System::Container
    #     configure do |config|
    #       # ...
    #       config.loader MyLoader.new
    #     end
    #   end
    #
    # @api public
    class Loader
      extend Dry::Configurable

      setting :inflector, Dry::Inflector.new

      # @!attribute [r] inflector
      #   @return [Object] Inflector backend
      attr_reader :inflector

      attr_reader :path

      attr_reader :args

      # @api private
      def initialize(path, *args, inflector: self.class.config.inflector, &block)
        @path = path
        @args = args
        @inflector = inflector

        call(&block) if block_given?
      end

      def require_file
        require(path)
      end

      def call(&block)
        require_file

        block.call(self) if block_given?

        self
      end

      def instance(*args)
        if singleton?
          constant.instance(*args)
        else
          constant.new(*args)
        end
      end

      private

      # @api private
      def constant
        @constant ||= inflector.constantize(inflector.camelize(path))
      end

      # @api private
      def singleton?
        constant.respond_to?(:instance) && !constant.respond_to?(:new)
      end
    end
  end
end
