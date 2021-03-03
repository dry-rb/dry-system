require "concurrent/map"
require "dry/configurable"
require "dry/system/errors"
require_relative "component_dir"

module Dry
  module System
    module Config
      class ComponentDirs
        attr_reader :dirs

        def initialize
          @dirs = Concurrent::Map.new
        end

        def initialize_copy(source)
          super
          @dirs = source.dirs.dup
        end

        def add(path_or_component_dir, &block)
          if path_or_component_dir.is_a?(ComponentDir)
            add_component_dir(path_or_component_dir)
          else
            build_and_add_component_dir(path_or_component_dir, &block)
          end
        end

        def to_a
          dirs.values
        end

        def each(&block)
          to_a.each(&block)
        end

        private

        def build_and_add_component_dir(path, &block)
          add_component_dir(ComponentDir.new(path, &block))
        end

        def add_component_dir(dir)
          raise ComponentDirAlreadyAddedError, dir.path if dirs.key?(dir.path)

          dirs[dir.path] = dir
        end
      end
    end
  end
end
