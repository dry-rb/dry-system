# frozen_string_literal: true

require "pathname"

require "dry-auto_inject"
require "dry-configurable"
require "dry-container"
require "dry/inflector"

require "dry/core/constants"
require "dry/core/deprecations"

require "dry/system"
require "dry/system/auto_registrar"
require "dry/system/booter"
require "dry/system/component"
require "dry/system/constants"
require "dry/system/errors"
require "dry/system/identifier"
require "dry/system/importer"
require "dry/system/indirect_component"
require "dry/system/manual_registrar"
require "dry/system/plugins"
require "dry/system/provider"

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
      setting :registrations_dir, default: "container"
      setting :component_dirs, default: Config::ComponentDirs.new, cloneable: true
      setting :inflector, default: Dry::Inflector.new
      setting :booter, default: Dry::System::Booter
      setting :auto_registrar, default: Dry::System::AutoRegistrar
      setting :manual_registrar, default: Dry::System::ManualRegistrar
      setting :importer, default: Dry::System::Importer
      setting :providers, default: {}, reader: true, constructor: :dup.to_proc

      class << self
        def strategies(value = nil)
          if value
            @strategies = value
          else
            @strategies ||= Dry::AutoInject::Strategies
          end
        end

        extend Dry::Core::Deprecations["Dry::System::Container"]

        # Define a new configuration setting
        #
        # @see https://dry-rb.org/gems/dry-configurable
        #
        # @api public
        def setting(name, default = Dry::Core::Constants::Undefined, **options, &block)
          super(name, default, **options, &block)
          # TODO: dry-configurable needs a public API for this
          config._settings << _settings[name]
          self
        end

        # Configures the container
        #
        # @example
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       config.root = Pathname("/path/to/app")
        #       config.name = :my_app
        #       config.auto_register = %w(lib/apis lib/core)
        #     end
        #   end
        #
        # @return [self]
        #
        # @api public
        def configure(&block)
          hooks[:before_configure].each { |hook| instance_eval(&hook) }
          super(&block)
          hooks[:after_configure].each { |hook| instance_eval(&hook) }
          self
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
        def import(other)
          case other
          when Hash then importer.register(other)
          when Dry::Container::Namespace then super
          else
            raise ArgumentError, <<-STR
              +other+ must be a hash of names and systems, or a Dry::Container namespace
            STR
          end
        end

        # Registers a provider and its lifecycle hooks
        #
        # By convention, you should place a file for each provider in one of the
        # configured `provider_dirs`, and they will be loaded on demand when components
        # are loaded in isolation, or during container finalization.
        #
        # @example
        #   # system/container.rb
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       config.root = Pathname("/path/to/app")
        #     end
        #
        #   # system/providers/db.rb
        #   #
        #   # Simple provider registration
        #   MyApp.register_provider(:db) do
        #     require "db"
        #     register("db", DB.new)
        #   end
        #
        #   # system/providers/db.rb
        #   #
        #   # Provider registration with lifecycle triggers
        #   MyApp.register_provider(:db) do |container|
        #     init do
        #       require "db"
        #       DB.configure(ENV["DB_URL"])
        #       container.register("db", DB.new)
        #     end
        #
        #     start do
        #       container["db"].establish_connection
        #     end
        #
        #     stop do
        #       container["db"].close_connection
        #     end
        #   end
        #
        #   # system/providers/db.rb
        #   #
        #   # Provider registration which uses another provider
        #   MyApp.register_provider(:db) do |container|
        #     use :logger
        #
        #     start do
        #       require "db"
        #       DB.configure(ENV['DB_URL'], logger: logger)
        #       container.register("db", DB.new)
        #     end
        #   end
        #
        #   # system/boot/db.rb
        #   #
        #   # Provider registration under a namespace. This will register the
        #   # db object with the "persistence.db" key
        #   MyApp.register_provider(:persistence, namespace: "db") do
        #     require "db"
        #     DB.configure(ENV["DB_URL"])
        #     register("db", DB.new)
        #   end
        #
        # @param name [Symbol] a unique name for the provider
        #
        # @see ProviderLifecycle
        #
        # @return [self]
        #
        # @api public
        def register_provider(name, namespace: nil, from: nil, source: nil, &block)
          raise ProviderAlreadyRegisteredError, name if providers.key?(name)

          provider =
            if from
              provider_from_source(
                name,
                namespace: namespace,
                source: source || name,
                group: from,
                &block
              )
            else
              provider(name, namespace: namespace, &block)
            end

          booter.register_provider provider

          providers[name] = provider
        end

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

        # @api private
        private def provider_from_source(name, source:, group:, namespace:, &block)
          System.source_providers.resolve(name: source, group: group)
            .to_provider(name: name, namespace: namespace, container: self, refinement_block: block)
        end

        # @api private
        private def provider(name, namespace:, &block)
          Provider.new(name: name, namespace: namespace, container: self, lifecycle_block: block)
        end

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

          yield(self) if block

          importer.finalize!
          booter.finalize!
          manual_registrar.finalize!
          auto_registrar.finalize!

          @__finalized__ = true

          self.freeze if freeze
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
          booter.start(name)
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
        # @param [Symbol] name The name of the registered provider to prepare
        #
        # @return [self]
        #
        # @api public
        def prepare(name)
          booter.prepare(name)
          self
        end
        deprecate :init, :prepare

        # Stop a specific component but calls only `stop` lifecycle trigger
        #
        # @example
        #   MyApp.stop(:persistence)
        #
        # @param [Symbol] name The name of a registered bootable component
        #
        # @return [self]
        #
        # @api public
        def stop(name)
          booter.stop(name)
          self
        end

        def shutdown!
          booter.shutdown
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
        # @param [Array<String>] dirs
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
          manual_registrar.(name)
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
        def injector(options = {strategies: strategies})
          Dry::AutoInject(self, options)
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
        #   @param [String,Symbol] key The key
        #   @return [Boolean]
        #   @api public
        #

        # Check if identifier is registered.
        # If not, try to load the component
        #
        # @param [String,Symbol] key Identifier
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
        def booter
          @booter ||= config.booter.new(provider_paths)
        end

        # rubocop:disable Metrics/PerceivedComplexity, Layout/LineLength
        # @api private
        def provider_paths
          provider_dirs = config.provider_dirs
          bootable_dirs = config.bootable_dirs || ["system/boot"]

          if config.provider_dirs == ["system/providers"] && \
             provider_dirs.none? { |d| root.join(d).exist? } && \
             bootable_dirs.any? { |d| root.join(d).exist? }
            Dry::Core::Deprecations.announce(
              "Dry::System::Container.config.bootable_dirs (defaulting to 'system/boot')",
              "Use `Dry::System::Container.config.provider_dirs` (defaulting to 'system/providers') instead",
              tag: "dry-system",
              uplevel: 2
            )

            provider_dirs = bootable_dirs
          end

          provider_dirs.map { |dir|
            dir = Pathname(dir)

            if dir.relative?
              root.join(dir)
            else
              dir
            end
          }
        end
        # rubocop:enable Metrics/PerceivedComplexity, Layout/LineLength

        # @api private
        def auto_registrar
          @auto_registrar ||= config.auto_registrar.new(self)
        end

        # @api private
        def manual_registrar
          @manual_registrar ||= config.manual_registrar.new(self)
        end

        # @api private
        def importer
          @importer ||= config.importer.new(self)
        end

        # @api private
        def after(event, &block)
          hooks[:"after_#{event}"] << block
        end

        # @api private
        def before(event, &block)
          hooks[:"before_#{event}"] << block
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

          klass.instance_variable_set(:@__finalized__, false)

          super
        end

        protected

        # @api private
        def load_component(key)
          return self if registered?(key)

          if (provider = booter.find_provider(key))
            booter.start(provider)
            return self
          end

          component = find_component(key)

          booter.boot_dependency(component)
          return self if registered?(key)

          if component.loadable?
            load_local_component(component)
          elsif manual_registrar.file_exists?(component)
            manual_registrar.(component)
          elsif importer.key?(component.identifier.root_key)
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

          container = importer[import_namespace]

          container.load_component(identifier.namespaced(from: import_namespace, to: nil).key)

          importer.(import_namespace, container)
        end

        def find_component(key)
          # Find the first matching component from within the configured component dirs.
          # If no matching component is found, return a null component; this fallback is
          # important because the component may still be loadable via the manual registrar
          # or an imported container.
          component_dirs.detect { |dir|
            if (component = dir.component_for_key(key))
              break component
            end
          } || IndirectComponent.new(Identifier.new(key, separator: config.namespace_separator))
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
