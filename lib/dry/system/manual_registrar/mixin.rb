module Dry
  module System
    module ManualRegistrar
      module Mixin
        # @api public
        def load_registrations!(name)
          manual_registrar.call(name)
          self
        end
      end
    end
  end
end
