module Dry
  module System
    class Container
      # Incuded only in the Test environment
      # Sending the message enable_stubs! allow you to stub components after
      # finalize your container in your tests.
      #
      # @api private
      module Stubs
        def finalize!(&block)
          super(freezable: false, &block)
        end
      end

      class << self
        def enable_stubs!
          extend ::Dry::System::Container::Stubs
        end
      end
    end
  end
end
