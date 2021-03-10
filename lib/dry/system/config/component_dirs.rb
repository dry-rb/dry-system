require "concurrent/map"
require "dry/configurable"
require "dry/system/errors"
require_relative "component_dir"

module Dry
  module System
    module Config
      class ComponentDirs
        include Dry::Configurable

        setting :auto_register, true
        setting :add_to_load_path, true
        setting :default_namespace
        setting :loader
        setting :memoize, false

        attr_reader :dirs

        def initialize
          @dirs = Concurrent::Map.new
        end

        def initialize_copy(source)
          super
          @dirs = source.dirs.dup
        end

        def default_config
          config
        end

        def add(path)
          raise ComponentDirAlreadyAddedError, path if dirs.key?(path)

          dir = ComponentDir.new(path)

          default_config.values.each do |key, val|
            dir.public_send(:"#{key}=", val)
          end

          yield dir if block_given?

          dirs[path] = dir
        end

        def to_a
          dirs.values
        end

        def each(&block)
          to_a.each(&block)
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
