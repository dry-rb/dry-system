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
    #       config.component_dirs.loader = MyLoader
    #     end
    #   end
    #
    # @api public
    class Loader
      class << self
        # Requires the component's source file
        #
        # @api public
        def require!(component)
          require(component.path) if component.file_exists?
          self
        end

        # Returns an instance of the component
        #
        # Provided optional args are passed to object's constructor
        #
        # @param [Array] args Optional constructor args
        #
        # @return [Object]
        #
        # @api public
        def call(component, *args)
          require!(component)

          constant = self.constant(component)

          if singleton?(constant)
            constant.instance(*args)
          else
            constant.new(*args)
          end
        end
        ruby2_keywords(:call) if respond_to?(:ruby2_keywords, true)

        # Returns the component's class constant
        #
        # @return [Class]
        #
        # @api public
        def constant(component)
          inflector = component.inflector

          inflector.constantize(inflector.camelize(component.path))
        end

        private

        def singleton?(constant)
          constant.respond_to?(:instance) && !constant.respond_to?(:new)
        end
      end
    end
  end
end
