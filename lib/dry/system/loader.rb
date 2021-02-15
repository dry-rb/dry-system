# frozen_string_literal: true

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
      # @!attribute [r] component
      #   @return [Dry::System::Component] Component to be loaded
      #   @api private
      attr_reader :component

      # @api private
      def initialize(component)
        @component = component
      end

      # Requires the component's source file
      #
      # @api public
      def require!
        require(component.path) if component.file_exists?
        self
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
        require!

        if singleton?(constant)
          constant.instance(*args)
        else
          constant.new(*args)
        end
      end
      ruby2_keywords(:call) if respond_to?(:ruby2_keywords, true)

      # Return component's class constant
      #
      # @return [Class]
      #
      # @api public
      def constant
        inflector.constantize(inflector.camelize(component.path))
      end

      private

      def singleton?(constant)
        constant.respond_to?(:instance) && !constant.respond_to?(:new)
      end

      def inflector
        component.inflector
      end
    end
  end
end
