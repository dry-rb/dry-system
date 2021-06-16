require "dry/configurable"
require "dry/system/loader"

module Dry
  module System
    module Config
      class ComponentDir
        include Dry::Configurable

        # @!group Settings

        # @!method auto_register=(policy)
        #
        #   Sets the auto-registration policy for the component dir.
        #
        #   This may be a simple boolean to enable or disable auto-registration for all
        #   components, or a proc accepting a `Dry::Sytem::Component` and returning a
        #   boolean to configure auto-registration on a per-component basis
        #
        #   Defaults to `true`.
        #
        #   @param policy [Boolean, Proc]
        #   @return [Boolean, Proc]
        #
        #   @example
        #     dir.auto_register = false
        #
        #   @example
        #     dir.auto_register = proc do |component|
        #       !component.start_with?("entities")
        #     end
        #
        #   @see auto_register
        #   @see Component
        #
        # @!method auto_register
        #
        #   Returns the configured auto-registration policy.
        #
        #   @return [Boolean, Proc] the configured policy
        #
        #   @see auto_register=
        setting :auto_register, default: true

        # @!method add_to_load_path=(policy)
        #
        #   Sets whether the dir should be added to the `$LOAD_PATH` after the container
        #   is configured.
        #
        #   Defaults to `true`. This may need to be set to `false` when using a class
        #   autoloading system.
        #
        #   @param policy [Boolean]
        #   @return [Boolean]
        #
        #   @see add_to_load_path
        #   @see Container.configure
        #
        # @!method add_to_load_path
        #
        #   Returns the configured value.
        #
        #   @return [Boolean]
        #
        #   @see add_to_load_path=
        setting :add_to_load_path, default: true

        # @!method default_namespace=(leading_namespace)
        #
        #   Sets the leading namespace segments to be stripped when registering components
        #   from the dir in the container.
        #
        #   This is useful to configure when the dir contains components in a module
        #   namespace that you don't want repeated in their identifiers.
        #
        #   Defaults to `nil`.
        #
        #   @param leading_namespace [String, nil]
        #   @return [String, nil]
        #
        #   @example
        #     dir.default_namespace = "my_app"
        #
        #   @example
        #     dir.default_namespace = "my_app.admin"
        #
        #   @see default_namespace
        #
        # @!method default_namespace
        #
        #   Returns the configured value.
        #
        #   @return [String, nil]
        #
        #   @see default_namespace=

        # FIXME: fix docs above
        # FIXME: this default value, while true, is kind of gross
        setting :namespaces, [nil].freeze do |namespaces|
          namespaces.map { |ns|
            if ns.is_a?(Array)
              ns
            else
              [ns, ns]
            end
          }
        end

        # TODO: add deprecated default_namespace setting
        # TODO: add `namespace` setting for nicer shortcut

        # @!method loader=(loader)
        #
        #   Sets the loader to use when registering coponents from the dir in the container.
        #
        #   Defaults to `Dry::System::Loader`.
        #
        #   When using a class autoloader, consider using `Dry::System::Loader::Autoloading`
        #
        #   @param loader [#call] the loader
        #   @return [#call] the configured loader
        #
        #   @see loader
        #   @see Loader
        #   @see Loader::Autoloading
        #
        # @!method loader
        #
        #   Returns the configured loader.
        #
        #   @return [#call]
        #
        #   @see loader=
        setting :loader, default: Dry::System::Loader

        # @!method memoize=(policy)
        #
        #   Sets whether to memoize components from the dir when registered in the
        #   container.
        #
        #   This may be a simple boolean to enable or disable memoization for all
        #   components, or a proc accepting a `Dry::Sytem::Component` and returning a
        #   boolean to configure memoization on a per-component basis
        #
        #   Defaults to `false`.
        #
        #   @param policy [Boolean, Proc]
        #   @return [Boolean, Proc] the configured memoization policy
        #
        #   @example
        #     dir.memoize = true
        #
        #   @example
        #     dir.memoize = proc do |component|
        #       !component.start_with?("providers")
        #     end
        #
        #   @see memoize
        #   @see Component
        #
        # @!method memoize
        #
        #   Returns the configured memoization policy.
        #
        #   @return [Boolean, Proc] the configured memoization policy
        #
        #   @see memoize=
        setting :memoize, default: false

        # @!endgroup

        # Returns the component dir path, relative to the configured container root
        #
        # @return [String] the path
        attr_reader :path

        # @api private
        def initialize(path)
          super()
          @path = path
          yield self if block_given?
        end

        # @api private
        def auto_register?
          !!config.auto_register
        end

        # Returns true if a setting has been explicitly configured and is not returning
        # just a default value.
        #
        # This is used to determine which settings from `ComponentDirs` should be applied
        # as additional defaults.
        #
        # @api private
        def configured?(key)
          config._settings[key].input_defined?
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
