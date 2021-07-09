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

        # Settings from ComponentDir are configured here as defaults for all added dirs
        ComponentDir._settings.each do |setting|
          _settings << setting.dup
        end

        # @!group Settings

        # @!method auto_register=(value)
        #
        #   Sets a default `auto_register` for all added component dirs
        #
        #   @see ComponentDir.auto_register
        #   @see auto_register
        #
        # @!method auto_register
        #
        #   Returns the configured default `auto_register`
        #
        #   @see auto_register=

        # @!method add_to_load_path=(value)
        #
        #   Sets a default `add_to_load_path` value for all added component dirs
        #
        #   @see ComponentDir.add_to_load_path
        #   @see add_to_load_path
        #
        # @!method add_to_load_path
        #
        #   Returns the configured default `add_to_load_path`
        #
        #   @see add_to_load_path=

        # @!method default_namespace=(value)
        #
        #   Sets a default `default_namespace` value for all added component dirs
        #
        #   @see ComponentDir.default_namespace
        #   @see default_namespace
        #
        # @!method default_namespace
        #
        #   Returns the configured default `default_namespace`
        #
        #   @see default_namespace=

        # @!method loader=(value)
        #
        #   Sets a default `loader` value for all added component dirs
        #
        #   @see ComponentDir.loader
        #   @see loader
        #
        # @!method loader
        #
        #   Returns the configured default `loader`
        #
        #   @see loader=

        # @!method memoize=(value)
        #
        #   Sets a default `memoize` value for all added component dirs
        #
        #   @see ComponentDir.memoize
        #   @see memoize
        #
        # @!method memoize
        #
        #   Returns the configured default `memoize`
        #
        #   @see memoize=

        # @!endgroup

        # @api private
        def initialize
          @dirs = Concurrent::Map.new
        end

        # @api private
        def initialize_copy(source)
          super
          @dirs = source.dirs.dup
        end

        # Adds and configures a component dir
        #
        # @param path [String] the path for the component dir, relative to the configured
        #   container root
        #
        # @yieldparam dir [ComponentDir] the component dir to configure
        #
        # @return [ComponentDir] the added component dir
        #
        # @example
        #   component_dirs.add "lib" do |dir|
        #     dir.default_namespace = "my_app"
        #   end
        #
        # @see ComponentDir
        def add(path)
          raise ComponentDirAlreadyAddedError, path if dirs.key?(path)

          dirs[path] = ComponentDir.new(path).tap do |dir|
            # TODO: I switched this order... does it feel OK?
            yield dir if block_given?
            apply_defaults_to_dir(dir)
          end
        end

        # Returns the added component dirs, with default settings applied
        #
        # @return [Hash<String, ComponentDir>] the component dirs as a hash, keyed by path
        def dirs
          @dirs.each { |_, dir| apply_defaults_to_dir(dir) }
        end

        # Returns the added component dirs, with default settings applied
        #
        # @return [Array<ComponentDir>]
        def to_a
          dirs.values
        end

        # Calls the given block once for each added component dir, passing the dir as an
        # argument.
        #
        # @yieldparam dir [ComponentDir] the yielded component dir
        def each(&block)
          to_a.each(&block)
        end

        private

        # Apply default settings to a component dir. This is run every time the dirs are
        # accessed to ensure defaults are applied regardless of when new component dirs
        # are added. This method must be idempotent.
        #
        # @return [void]
        def apply_defaults_to_dir(dir)
          dir.config.values.each do |key, _value|
            if configured?(key) && !dir.configured?(key)
              dir.public_send(:"#{key}=", public_send(key).dup)
            end
          end
        end

        # Returns true if a setting has been explicitly configured and is not returning
        # just a default value.
        #
        # This is used to determine which settings should be applied to added component
        # dirs as additional defaults.
        def configured?(key)
          # UGH
          if key == :namespaces
            !config.namespaces.empty?
          else
            config._settings[key].input_defined?
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
