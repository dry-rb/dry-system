require "concurrent/map"
require "dry/configurable"
require "dry/system/constants"
require "dry/system/errors"
require "dry/system/loader"
require_relative "component_dir"

module Dry
  module System
    module Config
      class ComponentDirs
        include Dry::Configurable

        setting :auto_register, true
        setting :add_to_load_path, true
        setting :default_namespace
        setting :loader, Dry::System::Loader
        setting :memoize, false

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

        # Apply global default settings to a component dir. This is run every time the
        # dirs are accessed, so this must be idempotent
        #
        # @return [void]
        def apply_defaults_to_dir(dir)
          # Copy the existing config so we don't lose it after applying defaults
          dir_config = dir.config.dup

          # Apply the defaults
          config.values.each do |key, val|
            dir.public_send(:"#{key}=", val)
          end

          # Reapply the dir's own config over the defaults, but only the values that are
          # different from the setting defaults. This ensures we don't overwrite globals
          # with meaningful, user-configured values.
          dir_config.values.each do |key, val|
            default_value = Undefined.coalesce(dir.class._settings[key].default, nil)

            if val != default_value
              dir.public_send(:"#{key}=", val)
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
