require 'dry/system/manual_registrar/mixin'
require 'dry/system/manual_registrar/manual_registrar'
require 'dry/system/plugins/plugin'

module Dry
  module System
    module ManualRegistrar
      class Plugin < Plugin
        config.identifier = :manual_registrar

        def initialize(container, *args)
          super

          container.send(:extend, Mixin)
          container.setting(:registrations_dir, 'container'.freeze)
        end

        def instance
          path = config.root.join(config.registrations_dir)
          @instance ||= ManualRegistrar.new(path)
        end

        def key_missing(identified)
          if instance.file_exists?(identified)
            instance.call(identified)
          end
        end

        def after_configure(config)
          @config = config
        end

        def finalize!
          instance.finalize!
        end
      end
    end
  end
end
