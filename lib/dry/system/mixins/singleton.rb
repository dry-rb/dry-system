# frozen_string_literal: true

module Dry
  module System
    module Mixins
      # This Mixin is intended for the auto register to inject
      # 'singleton like' instances to the Container while allowing to
      # create new instances for testing purposes
      # e.g
      # class Foo
      #   include Dry::System::Mixins::Singleton
      #   include Import['bar']
      # end
      #
      # the container will resolve 'foo' to Foo.instance as default
      # while allowing you to test it like Foo.new(bar: mock)
      module Singleton
        def self.included(base)
          base.extend(ClassMethods)
        end

        # Method that returns instance
        module ClassMethods
          def instance
            @instance ||= new
          end
        end
      end
    end
  end
end
