# frozen_string_literal: true

require "dry/inflector"

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
    #       config.loader MyLoader
    #     end
    #   end
    #
    # @api public
    class Loader
      # @!attribute [r] path
      #   @return [String] Path to component's file
      attr_reader :path

      # @!attribute [r] inflector
      #   @return [Object] Inflector backend
      attr_reader :inflector

      # @api private
      def initialize(path, inflector = Dry::Inflector.new)
        @path = path
        @inflector = inflector
      end

      # Returns component's instance
      #
      # Provided optional args are passed to object's constructor
      #
      # @param [Array] args Optional constructor args
      #
      # @return [Object]
      #
      # @api public
      def call(*args)
        if singleton?(constant)
          constant.instance(*args)
        else
          constant.new(*args)
        end
      end
      ruby2_keywords(:call) if respond_to?(:ruby2_keywords, true)

      def require!
        require path
      end

      # Return component's class constant
      #
      # @return [Class]
      #
      # @api public
      def constant
        inflector.constantize(inflector.camelize(path))
      end

      private

      # @api private
      def singleton?(constant)
        constant.respond_to?(:instance) && !constant.respond_to?(:new)
      end
    end
  end
end
