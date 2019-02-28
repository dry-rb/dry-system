require 'dry/system/plugins/manager'

module Dry
  module System
    module Plugins
      module Mixin


        def self.extended(klass)
          super

          klass.instance_variable_set(:@plugins, Manager.new(klass))
        end

        def inherited(klass)
          super


        end
      end
    end
  end
end