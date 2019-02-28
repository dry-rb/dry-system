require 'dry/system/importer/mixin'
require 'dry/system/importer/importer'
require 'dry/system/plugins/plugin'

module Dry
  module System
    module Importer
      class Plugin < Plugin
        config.identifier = :importer

        def initialize(container, *args)
          super

          container.send(:extend, Mixin)
        end

        def instance
          @instance ||= Importer.new(container)
        end

        def key_missing(identified)
          if instance.key?(identified.root_key)
            identified = identified.namespaced(identified.root_key)
            container = instance[identified.namespace]
            container[identified.identifier]
            instance.call(identified.namespace, container)
          end
        end

        def finalize
          instance.finalize!
        end
      end
    end
  end
end
