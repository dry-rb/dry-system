module Dry
  module System
    class Container
      # Incuded only in the Test environment
      # Sending the message enabled_stubs! allow you to stub finalize container
      # in your tests.
      #
      # @api private
      module Stub
        def finalize!(&block)
          yield(self) if block

          importer.finalize!
          booter.finalize!
          manual_registrar.finalize!
          auto_registrar.finalize!
        end
      end

      class << self
        def enabled_stubs!
          extend ::Dry::System::Container::Stub
        end
      end
    end
  end
end
