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
          require(component.require_path)
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
        def call(component, *args, isolate: false)
          require!(component)

          constant = self.constant(component)

          instance = if singleton?(constant)
            constant.instance(*args)
          else
            constant.new(*args)
          end

          if isolate
            constant_name_parts = constant.to_s.split("::")
            namespace = constant_name_parts.slice(0..-2).join("::")
            namespace_const = component.inflector.constantize(namespace)
            namespace_const.send(:remove_const, constant_name_parts.last)
          end

          instance
        end
        ruby2_keywords(:call) if respond_to?(:ruby2_keywords, true)

        # Returns the component's class constant
        #
        # @return [Class]
        #
        # @api public
        def constant(component)
          inflector = component.inflector
          inflector.constantize(inflector.camelize(component.const_path))
        end

        private

        def singleton?(constant)
          constant.respond_to?(:instance) && !constant.respond_to?(:new)
        end
      end
    end
  end
end
