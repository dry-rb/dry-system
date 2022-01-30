# frozen_string_literal: true

require "pathname"

require "dry-auto_inject"
require "dry-configurable"
require "dry-container"
require "dry/core/deprecations"
require "dry/inflector"

require "dry/system/auto_registrar"
require "dry/system/component"
require "dry/system/constants"
require "dry/system/errors"
require "dry/system/identifier"
require "dry/system/importer"
require "dry/system/indirect_component"
require "dry/system/manifest_registrar"
require "dry/system/plugins"
require "dry/system/provider_registrar"
require "dry/system/provider"
require "dry/system/provider/source"

require_relative "component_dir"
require_relative "config/component_dirs"

module Dry
  module System
    # Abstract container class to inherit from
    #
    # Container class is treated as a global registry with all system components.
    # Container can also import dependencies from other containers, which is
    # useful in complex systems that are split into sub-systems.
    #
    # Container can be finalized, which triggers loading of all the defined
    # components within a system, after finalization it becomes frozen. This
    # typically happens in cases like booting a web application.
    #
    # Before finalization, Container can lazy-load components on demand. A
    # component can be a simple class defined in a single file, or a complex
    # component which has init/start/stop lifecycle, and it's defined in a boot
    # file. Components which specify their dependencies using Import module can
    # be safely required in complete isolation, and Container will resolve and
    # load these dependencies automatically.
    #
    # Furthermore, Container supports auto-registering components based on
    # dir/file naming conventions. This reduces a lot of boilerplate code as all
    # you have to do is to put your classes under configured directories and
    # their instances will be automatically registered within a container.
    #
    # Every container needs to be configured with following settings:
    #
    # * `:name` - a unique container name
    # * `:root` - a system root directory (defaults to `pwd`)
    #
    # @example
    #   class MyApp < Dry::System::Container
    #     configure do |config|
    #       config.name = :my_app
    #
    #       # this will auto-register classes from 'lib/components'. ie if you add
    #       # `lib/components/repo.rb` which defines `Repo` class, then it's
    #       # instance will be automatically available as `MyApp['repo']`
    #       config.auto_register = %w(lib/components)
    #     end
    #
    #     # this will configure $LOAD_PATH to include your `lib` dir
    #     add_dirs_to_load_paths!('lib')
    #   end
    #
    # @api public
    class Container
      extend Dry::Configurable
      extend Dry::Container::Mixin
      extend Dry::System::Plugins

      setting :name
      setting :root, default: Pathname.pwd.freeze, constructor: -> path { Pathname(path) }
      setting :provider_dirs, default: ["system/providers"]
      setting :bootable_dirs # Deprecated for provider_dirs, see .provider_paths below
      setting :registrations_dir, default: "system/registrations"
      setting :component_dirs, default: Config::ComponentDirs.new, cloneable: true
      setting :exports, reader: true
      setting :inflector, default: Dry::Inflector.new
      setting :auto_registrar, default: Dry::System::AutoRegistrar
      setting :manifest_registrar, default: Dry::System::ManifestRegistrar
      setting :provider_registrar, default: Dry::System::ProviderRegistrar
      setting :importer, default: Dry::System::Importer

      # We presume "." as key namespace separator. This is not intended to be
      # user-configurable.
      config.namespace_separator = KEY_SEPARATOR

      class << self
        extend Dry::Core::Deprecations["Dry::System::Container"]

        # @!method config
        #   Returns the configuration for the container
        #
        #   @example
        #     container.config.root = "/path/to/app"
        #     container.config.root # => #<Pathname:/path/to/app>
        #
        #   @return [Dry::Configurable::Config]
        #
        #   @api public

        # Yields a configuration object for the container, which you can use to modify the
        # configuration, then runs the after-`configured` hooks and finalizes (freezes)
        # the {config}.
        #
        # Does not finalize the config when given `finalize_config: false`
        #
        # @example
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       config.root = Pathname("/path/to/app")
        #       config.name = :my_app
        #     end
        #   end
        #
        # @param finalize_config [Boolean]
        #
        # @return [self]
        #
        # @see after
        #
        # @api public
        def configure(finalize_config: true, &block)
          super(&block)

          unless configured?
            hooks[:after_configure].each { |hook| instance_eval(&hook) }
            config.finalize! if finalize_config
            @__configured__ = true
          end

          self
        end

        # Marks the container as configured, runs the after-`configured` hooks, then
        # finalizes (freezes) the {config}.
        #
        # This method is useful to call if you're modifying the container's {config}
        # directly, rather than via the config object yielded when calling {configure}.
        #
        # Does not finalize the config if given `finalize_config: false`.
        #
        # @param finalize_config [Boolean]
        #
        # @return [self]
        #
        # @see after
        #
        # @api public
        def configured!(finalize_config: true)
          return self if configured?

          hooks[:after_configure].each { |hook| instance_eval(&hook) }
          config.finalize! if finalize_config
          @__configured__ = true

          self
        end

        def configured?
          @__configured__.equal?(true)
        end

        # Registers another container for import
        #
        # @example
        #   # system/container.rb
        #   class Core < Dry::System::Container
        #     configure do |config|
        #       config.root = Pathname("/path/to/app")
        #       config.auto_register = %w(lib/apis lib/core)
        #     end
        #   end
        #
        #   # apps/my_app/system/container.rb
        #   require 'system/container'
        #
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       config.root = Pathname("/path/to/app")
        #       config.auto_register = %w(lib/apis lib/core)
        #     end
        #
        #     import core: Core
        #   end
        #
        # @param other [Hash, Dry::Container::Namespace]
        #
        # @api public
        def import(keys: nil, from: nil, as: nil, **deprecated_import_hash) # rubocop:disable Style/KeywordParametersOrder, Layout/LineLength
          if deprecated_import_hash.any?
            Dry::Core::Deprecations.announce(
              "Dry::System::Container.import with {namespace => container} hash",
              "Use Dry::System::Container.import(from: container, as: namespace) instead",
              tag: "dry-system",
              uplevel: 1
            )

            deprecated_import_hash.each do |namespace, container|
              importer.register(container: container, namespace: namespace)
            end
            return self
          elsif from.nil? || as.nil?
            # These keyword arguments can become properly required in the params list once
            # we remove the deprecation shim above
            raise ArgumentError, "required keyword arguments: :from, :as"
          end

          importer.register(container: from, namespace: as, keys: keys)

          self
        end

        # rubocop:disable Layout/LineLength

        # @overload register_provider(name, namespace: nil, from: nil, source: nil, if: true, &block)
        #   Registers a provider and its lifecycle hooks
        #
        #   By convention, you should place a file for each provider in one of the
        #   configured `provider_dirs`, and they will be loaded on demand when components
        #   are loaded in isolation, or during container finalization.
        #
        #   @example
        #     # system/container.rb
        #     class MyApp < Dry::System::Container
        #       configure do |config|
        #         config.root = Pathname("/path/to/app")
        #       end
        #     end
        #
        #     # system/providers/db.rb
        #     #
        #     # Simple provider registration
        #     MyApp.register_provider(:db) do
        #       start do
        #         require "db"
        #         register("db", DB.new)
        #       end
        #     end
        #
        #     # system/providers/db.rb
        #     #
        #     # Provider registration with lifecycle triggers
        #     MyApp.register_provider(:db) do |container|
        #       init do
        #         require "db"
        #         DB.configure(ENV["DB_URL"])
        #         container.register("db", DB.new)
        #       end
        #
        #       start do
        #         container["db"].establish_connection
        #       end
        #
        #       stop do
        #         container["db"].close_connection
        #       end
        #     end
        #
        #     # system/providers/db.rb
        #     #
        #     # Provider registration which uses another provider
        #     MyApp.register_provider(:db) do |container|
        #       start do
        #         use :logger
        #
        #         require "db"
        #         DB.configure(ENV['DB_URL'], logger: logger)
        #         container.register("db", DB.new)
        #       end
        #     end
        #
        #     # system/boot/db.rb
        #     #
        #     # Provider registration under a namespace. This will register the
        #     # db object with the "persistence.db" key
        #     MyApp.register_provider(:persistence, namespace: "db") do
        #       start do
        #         require "db"
        #         DB.configure(ENV["DB_URL"])
        #         register("db", DB.new)
        #       end
        #     end
        #
        #   @param name [Symbol] a unique name for the provider
        #   @param namespace [String, nil] the key namespace to use for any registrations
        #     made during the provider's lifecycle
        #   @param from [Symbol, nil] the group for the external provider source (with the
        #     provider source name inferred from `name` or passsed explicitly as
        #     `source:`)
        #   @param source [Symbol, nil] the name of the external provider source to use
        #     (if different from the value provided as `name`)
        #   @param if [Boolean] a boolean to determine whether to register the provider
        #
        #   @see Provider
        #   @see Provider::Source
        #
        #   @return [self]
        #
        #   @api public
        def register_provider(...)
          providers.register_provider(...)
        end

        # rubocop:enable Layout/LineLength

        # @see .register_provider
        # @api public
        def boot(name, **opts, &block)
          Dry::Core::Deprecations.announce(
            "Dry::System::Container.boot",
            "Use `Dry::System::Container.register_provider` instead",
            tag: "dry-system",
            uplevel: 1
          )

          register_provider(
            name,
            namespace: opts[:namespace],
            from: opts[:from],
            source: opts[:key],
            &block
          )
        end
        deprecate :finalize, :boot

        # Return if a container was finalized
        #
        # @return [TrueClass, FalseClass]
        #
        # @api public
        def finalized?
          @__finalized__.equal?(true)
        end

        # Finalizes the container
        #
        # This triggers importing components from other containers, booting
        # registered components and auto-registering components. It should be
        # called only in places where you want to finalize your system as a
        # whole, ie when booting a web application
        #
        # @example
        #   # system/container.rb
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       config.root = Pathname("/path/to/app")
        #       config.name = :my_app
        #       config.auto_register = %w(lib/apis lib/core)
        #     end
        #   end
        #
        #   # You can put finalization file anywhere you want, ie system/boot.rb
        #   MyApp.finalize!
        #
        #   # If you need last-moment adjustments just before the finalization
        #   # you can pass a block and do it there
        #   MyApp.finalize! do |container|
        #     # stuff that only needs to happen for finalization
        #   end
        #
        # @return [self] frozen container
        #
        # @api public
        def finalize!(freeze: true, &block)
          return self if finalized?

          configured!

          hooks[:before_finalize].each { |hook| instance_eval(&hook) }
          yield(self) if block

          importer.finalize!
          providers.finalize!
          manifest_registrar.finalize!
          auto_registrar.finalize!

          @__finalized__ = true

          self.freeze if freeze
          hooks[:after_finalize].each { |hook| instance_eval(&hook) }
          self
        end

        # Starts a provider
        #
        # As a result, the provider's `prepare` and `start` lifecycle triggers are called
        #
        # @example
        #   MyApp.start(:persistence)
        #
        # @param name [Symbol] the name of a registered provider to start
        #
        # @return [self]
        #
        # @api public
        def start(name)
          providers.start(name)
          self
        end

        # Prepares a provider using its `prepare` lifecycle trigger
        #
        # Preparing (as opposed to starting) a provider is useful in places where some
        # aspects of a heavier dependency are needed, but its fully started environment
        #
        # @example
        #   MyApp.prepare(:persistence)
        #
        # @param name [Symbol] The name of the registered provider to prepare
        #
        # @return [self]
        #
        # @api public
        def prepare(name)
          providers.prepare(name)
          self
        end
        deprecate :init, :prepare

        # Stop a specific component but calls only `stop` lifecycle trigger
        #
        # @example
        #   MyApp.stop(:persistence)
        #
        # @param name [Symbol] The name of a registered bootable component
        #
        # @return [self]
        #
        # @api public
        def stop(name)
          providers.stop(name)
          self
        end

        # @api public
        def shutdown!
          providers.shutdown
          self
        end

        # Adds the directories (relative to the container's root) to the Ruby load path
        #
        # @example
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       # ...
        #     end
        #
        #     add_to_load_path!('lib')
        #   end
        #
        # @param dirs [Array<String>]
        #
        # @return [self]
        #
        # @api public
        def add_to_load_path!(*dirs)
          dirs.reverse.map(&root.method(:join)).each do |path|
            $LOAD_PATH.prepend(path.to_s) unless $LOAD_PATH.include?(path.to_s)
          end
          self
        end

        # @api public
        def load_registrations!(name)
          manifest_registrar.(name)
          self
        end

        # Builds injector for this container
        #
        # An injector is a useful mixin which injects dependencies into
        # automatically defined constructor.
        #
        # @example
        #   # Define an injection mixin
        #   #
        #   # system/import.rb
        #   Import = MyApp.injector
        #
        #   # Use it in your auto-registered classes
        #   #
        #   # lib/user_repo.rb
        #   require 'import'
        #
        #   class UserRepo
        #     include Import['persistence.db']
        #   end
        #
        #   MyApp['user_repo].db # instance under 'persistence.db' key
        #
        # @param options [Hash] injector options
        #
        # @api public
        def injector(**options)
          Dry::AutoInject(self, **options)
        end

        # Requires one or more files relative to the container's root
        #
        # @example
        #   # single file
        #   MyApp.require_from_root('lib/core')
        #
        #   # glob
        #   MyApp.require_from_root('lib/**/*')
        #
        # @param paths [Array<String>] one or more paths, supports globs too
        #
        # @api public
        def require_from_root(*paths)
          paths.flat_map { |path|
            path.to_s.include?("*") ? ::Dir[root.join(path)].sort : root.join(path)
          }.each { |path|
            Kernel.require path.to_s
          }
        end

        # Returns container's root path
        #
        # @example
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       config.root = Pathname('/my/app')
        #     end
        #   end
        #
        #   MyApp.root # returns '/my/app' pathname
        #
        # @return [Pathname]
        #
        # @api public
        def root
          config.root
        end

        # @api public
        def resolve(key)
          load_component(key) unless finalized?

          super
        end

        alias_method :registered?, :key?
        #
        # @!method registered?(key)
        #   Whether a +key+ is registered (doesn't trigger loading)
        #   @param key [String,Symbol] The key
        #   @return [Boolean]
        #   @api public
        #

        # Check if identifier is registered.
        # If not, try to load the component
        #
        # @param key [String,Symbol] Identifier
        # @return [Boolean]
        #
        # @api public
        def key?(key)
          if finalized?
            registered?(key)
          else
            registered?(key) || resolve(key) { return false }
            true
          end
        end

        # @api private
        def component_dirs
          config.component_dirs.to_a.map { |dir| ComponentDir.new(config: dir, container: self) }
        end

        # @api private
        def providers
          @providers ||= config.provider_registrar.new(self)
        end
        deprecate :booter, :providers

        # @api private
        def auto_registrar
          @auto_registrar ||= config.auto_registrar.new(self)
        end

        # @api private
        def manifest_registrar
          @manifest_registrar ||= config.manifest_registrar.new(self)
        end

        # @api private
        def importer
          @importer ||= config.importer.new(self)
        end

        # Registers a callback hook to run before container lifecycle events.
        #
        # Currently, the only supported event is `:finalized`. This hook is called when
        # you run `{finalize!}`.
        #
        # When the given block is called, `self` is the container class, and no block
        # arguments are given.
        #
        # @param event [Symbol] the event name
        # @param block [Proc] the callback hook to run
        #
        # @return [self]
        #
        # @api public
        def before(event, &block)
          hooks[:"before_#{event}"] << block
          self
        end

        # Registers a callback hook to run after container lifecycle events.
        #
        # The supported events are:
        #
        # - `:configured`, called when you run {configure} or {configured!}, or when
        #   running {finalize!} and neither of the prior two methods have been called.
        # - `:finalized`, called when you run {finalize!}.
        #
        # When the given block is called, `self` is the container class, and no block
        # arguments are given.
        #
        # @param event [Symbol] the event name
        # @param block [Proc] the callback hook to run
        #
        # @return [self]
        #
        # @api public
        def after(event, &block)
          hooks[:"after_#{event}"] << block
          self
        end

        # @api private
        def hooks
          @hooks ||= Hash.new { |h, k| h[k] = [] }
        end

        # @api private
        def inherited(klass)
          hooks.each do |event, blocks|
            klass.hooks[event].concat blocks.dup
          end

          klass.instance_variable_set(:@__configured__, false)
          klass.instance_variable_set(:@__finalized__, false)

          super
        end

        protected

        # @api private
        def load_component(key)
          return self if registered?(key)

          if (provider = providers.find_and_load_provider(key))
            provider.start
            return self
          end

          component = find_component(key)

          providers.start_provider_dependency(component)
          return self if registered?(key)

          if component.loadable?
            load_local_component(component)
          elsif manifest_registrar.file_exists?(component)
            manifest_registrar.(component)
          elsif importer.namespace?(component.identifier.root_key)
            load_imported_component(component.identifier)
          end

          self
        end

        private

        def load_local_component(component)
          if component.auto_register?
            register(component.identifier, memoize: component.memoize?) { component.instance }
          end
        end

        def load_imported_component(identifier)
          import_namespace = identifier.root_key

          return unless importer.namespace?(import_namespace)

          import_key = identifier.namespaced(from: import_namespace, to: nil).key

          importer.import(import_namespace, keys: [import_key])
        end

        def find_component(key)
          # Find the first matching component from within the configured component dirs.
          # If no matching component is found, return a null component; this fallback is
          # important because the component may still be loadable via the manifest
          # registrar or an imported container.
          component_dirs.detect { |dir|
            if (component = dir.component_for_key(key))
              break component
            end
          } || IndirectComponent.new(Identifier.new(key))
        end
      end

      # Default hooks
      after :configure do
        # Add appropriately configured component dirs to the load path
        #
        # Do this in a single pass to preserve ordering (i.e. earliest dirs win)
        paths = config.component_dirs.to_a.each_with_object([]) { |dir, arr|
          arr << dir.path if dir.add_to_load_path
        }
        add_to_load_path!(*paths)
      end
    end
  end
end
