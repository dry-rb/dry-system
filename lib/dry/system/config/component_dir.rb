# frozen_string_literal: true

require "dry/configurable"
require "dry/core/deprecations"
require "dry/system/constants"
require "dry/system/loader"
require_relative "namespaces"

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
        #       !component.identifier.start_with?("entities")
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

        # @!method namespaces
        #
        #   Returns the configured namespaces for the component dir.
        #
        #   Allows namespaces to added on the returned object via {Namespaces#add}.
        #
        #   @see Namespaces#add
        #
        #   @return [Namespaces] the namespaces
        setting :namespaces, default: Namespaces.new, cloneable: true

        def default_namespace=(namespace)
          Dry::Core::Deprecations.announce(
            "Dry::System::Config::ComponentDir#default_namespace=",
            "Add a namespace instead: `dir.namespaces.add #{namespace.to_s.inspect}, key: nil`",
            tag: "dry-system",
            uplevel: 1
          )

          # We don't have the configured separator here, so the best we can do is guess
          # that it's a dot
          namespace_path = namespace.gsub(".", PATH_SEPARATOR)

          return if namespaces.namespaces[namespace_path]

          namespaces.add namespace_path, key: nil
        end

        def default_namespace
          Dry::Core::Deprecations.announce(
            "Dry::System::Config::ComponentDir#default_namespace",
            "Use namespaces instead, e.g. `dir.namespaces`",
            tag: "dry-system",
            uplevel: 1
          )

          ns_path = namespaces.to_a.reject(&:root?).first&.path

          # We don't have the configured separator here, so the best we can do is guess
          # that it's a dot
          ns_path&.gsub(PATH_SEPARATOR, ".")
        end

        # @!method loader=(loader)
        #
        #   Sets the loader to use when registering components from the dir in the
        #   container.
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
        #       !component.identifier.start_with?("providers")
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

        # Returns true if the given setting has been explicitly configured by the user
        #
        # This is used when determining whether to apply system-wide default values to a
        # component dir (explicitly configured settings will not be overridden by
        # defaults)
        #
        # @param key [Symbol] the setting name
        #
        # @return [Boolean]
        #
        # @see Dry::System::Config::ComponentDirs#apply_defaults_to_dir
        # @api private
        def configured?(key)
          case key
          when :namespaces
            # Because we mutate the default value for the `namespaces` setting, rather
            # than assign a new one, to check if it's configured we must see whether any
            # namespaces have been added
            !config.namespaces.empty?
          else
            config._settings[key].input_defined?
          end
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
