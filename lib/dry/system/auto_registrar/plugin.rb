require 'dry/system/auto_registrar/mixin'
require 'dry/system/auto_registrar/auto_registrar'
require 'dry/system/plugins/plugin'

module Dry
  module System
    module AutoRegistrar
      class Plugin < Plugin
        config.identifier = :auto_registrar

        def initialize(container, *args)
          super

          container.send(:extend, Mixin)
          container.setting(:auto_register, [])
        end

        def instance
          @instance ||=
            AutoRegistrar.new(
              container,
              config.root,
              loader: config.loader,
              default_namespace: config.default_namespace
            )
        end

        def key_missing(identified)
          if identified.file_exists?(container.load_paths)
            instance.auto_register(identified)
          end
        end

        def after_configure(config)
          @config = config
        end

        def finalize
          instance.finalize!(config.auto_register)
        end
      end
    end
  end
end
