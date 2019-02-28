module Dry
  module System
    module AutoRegistrar
      module Mixin
        # Auto-registers components from the provided directory
        #
        # Typically you want to configure auto_register directories, and it will
        # work automatically. Use this method in cases where you want to have an
        # explicit way where some components are auto-registered, or if you want
        # to exclude some components from being auto-registered
        #
        # @example
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       # ...
        #     end
        #
        #     # with a dir
        #     auto_register!('lib/core')
        #
        #     # with a dir and a custom registration block
        #     auto_register!('lib/core') do |config|
        #       config.instance do |component|
        #         # custom way of initializing a component
        #       end
        #
        #       config.exclude do |component|
        #         # return true to exclude component from auto-registration
        #       end
        #     end
        #   end
        #
        # @param [String] dir The dir name relative to the root dir
        #
        # @yield AutoRegistrar::Configuration
        # @see AutoRegistrar::Configuration
        #
        # @return [self]
        #
        # @api public
        def auto_register!(dir, &block)
          auto_registrar.call(dir, &block)
          self
        end
      end
    end
  end
end
