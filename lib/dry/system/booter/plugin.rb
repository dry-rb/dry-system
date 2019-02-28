require 'dry/system/booter/mixin'
require 'dry/system/booter/booter'
require 'dry/system/plugins/plugin'

module Dry
  module System
    module Booter
      class Plugin < Plugin
        config.identifier = :booter

        def initialize(container, *args)
          super

          container.send(:extend, Mixin)
        end

        def instance
          @instance ||= begin
            Dry::System.finalize!
            Booter.new(container, Dry::System.systems)
          end
        end

        def key_missing(identified)
          if provider = instance.provider_for(identified.identifier) || instance.provider_for(identified.root_key)
            instance.start(provider)
          end
        end

        def after_configure(config)
          boot_path = config.root.join("#{config.system_dir}/boot")

          Dir["#{boot_path.to_s}/**/#{RB_GLOB}"].map do |path|
            require(path)
          end
        end

        def finalize
          instance.finalize!
        end

        def shutdown
          instance.shutdown
        end
      end
    end
  end
end
