require 'dry/container/stub'

module Dry
  module System
    class Container
      # @api private
      module Stubs
        def finalize!(&block)
          super(freeze: false, &block)
        end
      end

      # Enables stubbing container's components
      #
      # @example
      #   require 'dry/system/stubs'
      #
      #   MyContainer.enable_stubs!
      #   MyContainer.finalize!
      #
      #   MyContainer.stub('some.component', some_stub_object)
      #
      # @return Container
      #
      # @api public
      def self.enable_stubs!
        super
        extend ::Dry::System::Container::Stubs
        self
      end
    end
  end
end
