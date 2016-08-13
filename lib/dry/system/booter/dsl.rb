module Dry
  module System
    class Booter
      attr_reader :path

      attr_reader :finalizers

      attr_reader :booted

      class DSL < BasicObject
        attr_reader :container

        def initialize(container, &block)
          @container = container
          instance_exec(container, &block)
        end

        def uses(*names)
          names.each do |name|
            container.boot!(name)
          end
        end

        def register(*args, &block)
          container.register(*args, &block)
        end

        private

        def method_missing(meth, *args, &block)
          if container.key?(meth)
            container[meth]
          else
            ::Kernel.public_send(meth, *args, &block)
          end
        end
      end
    end
  end
end
