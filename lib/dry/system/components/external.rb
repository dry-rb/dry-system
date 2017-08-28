require 'dry/system/components/bootable'

module Dry
  module System
    module Components
      class External < Components::Bootable
        def external?
          true
        end
      end
    end
  end
end
