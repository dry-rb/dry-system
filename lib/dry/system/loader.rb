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
          # byebug if component.key == "component"
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

          # puts "constantizing component #{component.path}"
          # byebug

          const_path = component.path

          # TODO: put this into component itself?
          # TODO: need to handle const_namespaces with multiple separators, i.e. translate them to paths


          # TODO: need to do something about that const_path.start_with condition, i.e.
          # encapsulate it somewhere sensible.... perhaps what we actually want to do here
          # is _only_ adjust the const_path if the path_namespace != the
          # const_namespace... we probably want more tests to account for the various
          # permutations of these two values

          # byebug if component.key =~ /admin_component/
          p component.key

          # FIXME: un-hack
          # FIXME: stop putting all those namespaces on the identifier - its gross - it should be on the component
          leading_const_namespace = component.identifier.const_namespace.gsub(".", "/") if component.identifier.const_namespace

          if leading_const_namespace && !const_path.start_with?(leading_const_namespace)
            const_path = "#{component.identifier.const_namespace}/#{const_path}"
          end

          # if component.identifier.const_namespace && component.identifier.const_namespace != component.identifier.path_namespace
          #   const_path = "#{component.identifier.const_namespace}/#{const_path}"
          # end

          # byebug if component.key == "component"
          # byebug

          inflector.constantize(inflector.camelize(const_path))
        end

        private

        def singleton?(constant)
          constant.respond_to?(:instance) && !constant.respond_to?(:new)
        end
      end
    end
  end
end
