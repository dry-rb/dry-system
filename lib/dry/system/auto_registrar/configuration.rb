module Dry
  module System
    class AutoRegistrar
      # Default auto_registrar configuration
      #
      # This is currently configured by default for every System::Container.
      # Configuration allows to define custom initializtion logic as well
      # as exclusion, for each component that is been register by Dry::System
      # auto-registration.
      #
      # @api private
      class Configuration
        DEFAULT_INSTANCE = -> component { component.instance }.freeze
        FALSE_PROC = -> * { false }.freeze

        def self.setting(name)
          define_method(name) do |&block|
            ivar = "@#{name}"

            if block
              instance_variable_set(ivar, block)
            else
              instance_variable_get(ivar)
            end
          end
        end

        setting :exclude
        setting :instance

        # @api private
        def initialize
          @instance = DEFAULT_INSTANCE
          @exclude = FALSE_PROC
        end
      end
    end
  end
end
