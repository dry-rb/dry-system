require "dry/configurable"

module Dry
  module System
    module Config
      class ComponentDir
        include Dry::Configurable

        setting :auto_register, true
        setting :add_to_load_path, true
        setting :default_namespace
        setting :loader
        setting :memoize, false

        attr_reader :path

        def initialize(path)
          super()
          @path = path
          yield self if block_given?
        end

        def auto_register?
          !!config.auto_register
        end

        private

        def method_missing(name, *args, &block)
          if config.respond_to?(name)
            config.public_send(name, *args, &block)
          else
            super
          end
        end

        def respond_to_missing?(name, include_all = false)
          config.respond_to?(name) || super
        end
      end
    end
  end
end
