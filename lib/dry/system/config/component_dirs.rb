require "concurrent/map"
require "dry/configurable"
require "dry/system/constants"
require "dry/system/errors"
require_relative "component_dir"

module Dry
  module System
    module Config
      class ComponentDirs
        include Dry::Configurable

        # Component dirs settings can be configured here to apply as defaults to all dirs
        @_settings = ComponentDir._settings.dup

        def initialize
          @dirs = Concurrent::Map.new
        end

        def initialize_copy(source)
          super
          @dirs = source.dirs.dup
        end

        def add(path)
          raise ComponentDirAlreadyAddedError, path if dirs.key?(path)

          dirs[path] = ComponentDir.new(path).tap do |dir|
            yield dir if block_given?
          end
        end

        def dirs
          @dirs.each { |_, dir| apply_defaults_to_dir(dir) }
        end

        def to_a
          dirs.values
        end

        def each(&block)
          to_a.each(&block)
        end

        private

        # Apply default settings to a component dir. This is run every time the dirs are
        # accessed, so this must be idempotent
        #
        # @return [void]
        def apply_defaults_to_dir(dir)
          dir.config.values.each do |key, value|
            # For each component dir setting, if the value is still the setting's default,
            # but the value configured _here_ is different, then apply it, since it must
            # have been explicitly configured as a default for all component dirs
            setting_default = Undefined.coalesce(dir.class._settings[key].default, nil)
            system_default_value = public_send(key)

            if value == setting_default && system_default_value != value
              dir.public_send(:"#{key}=", system_default_value)
            end
          end
        end

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
