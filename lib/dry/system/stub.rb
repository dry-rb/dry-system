module Dry
  module System
    class Container
      # Incuded only in the Test environment
      # Sending the message enable_stubs! allow you to stub components after
      # finalize your container in your tests.
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
        def enable_stubs!
          extend ::Dry::System::Container::Stub
        end
      end
    end
  end
end
