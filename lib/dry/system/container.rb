# frozen_string_literal: true

require "pathname"

require "dry-auto_inject"
require "dry-configurable"
require "dry-container"
require "dry/inflector"

require "dry/core/constants"
require "dry/core/deprecations"

require "dry/system"
require "dry/system/errors"
require "dry/system/booter"
require "dry/system/auto_registrar"
require "dry/system/manual_registrar"
require "dry/system/importer"
require "dry/system/component"
require "dry/system/constants"
require "dry/system/plugins"

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
    # * `:name` - a unique container identifier
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
      setting :system_dir, default: "system"
      setting :bootable_dirs, default: ["system/boot"]
      setting :registrations_dir, default: "container"
      setting :component_dirs, default: Config::ComponentDirs.new, cloneable: true
      setting :inflector, default: Dry::Inflector.new
      setting :booter, default: Dry::System::Booter
      setting :auto_registrar, default: Dry::System::AutoRegistrar
      setting :manual_registrar, default: Dry::System::ManualRegistrar
      setting :importer, default: Dry::System::Importer
      setting :components, default: {}, reader: true, constructor: :dup.to_proc

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
          @configure_self = true
          config._settings << _settings[name]
          @configure_self = false
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
          @hooks_initialized ||= true
          hooks[:before_configure].each { |hook| instance_eval(&hook) }
          super(&block)
          hooks[:after_configure].each { |hook| instance_eval(&hook) }
          self
        end

        def config
          if @hooks_initialized != true && finalized? != true && @configure_self != true
            klass = super
            super.instance_eval do
              def method_missing(meth, *args)
                setting = _settings[resolve(meth)]
                super unless setting
                if setting.writer?(meth)
                  raise "Config can't be accessed directly. Please use the #configure method"
                else
                  super
                end
              end #unless super.respond_to?(:method_missing)
            end
          end
          super
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

        # Registers finalization function for a bootable component
        #
        # By convention, boot files for components should be placed in a
        # `bootable_dirs` entry and they will be loaded on demand when
        # components are loaded in isolation, or during the finalization
        # process.
        #
        # @example
        #   # system/container.rb
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       config.root = Pathname("/path/to/app")
        #       config.name = :core
        #       config.auto_register = %w(lib/apis lib/core)
        #     end
        #
        #   # system/boot/db.rb
        #   #
        #   # Simple component registration
        #   MyApp.boot(:db) do |container|
        #     require 'db'
        #
        #     container.register(:db, DB.new)
        #   end
        #
        #   # system/boot/db.rb
        #   #
        #   # Component registration with lifecycle triggers
        #   MyApp.boot(:db) do |container|
        #     init do
        #       require 'db'
        #       DB.configure(ENV['DB_URL'])
        #       container.register(:db, DB.new)
        #     end
        #
        #     start do
        #       db.establish_connection
        #     end
        #
        #     stop do
        #       db.close_connection
        #     end
        #   end
        #
        #   # system/boot/db.rb
        #   #
        #   # Component registration which uses another bootable component
        #   MyApp.boot(:db) do |container|
        #     use :logger
        #
        #     start do
        #       require 'db'
        #       DB.configure(ENV['DB_URL'], logger: logger)
        #       container.register(:db, DB.new)
        #     end
        #   end
        #
        #   # system/boot/db.rb
        #   #
        #   # Component registration under a namespace. This will register the
        #   # db object under `persistence.db` key
        #   MyApp.namespace(:persistence) do |persistence|
        #     require 'db'
        #     DB.configure(ENV['DB_URL'], logger: logger)
        #     persistence.register(:db, DB.new)
        #   end
        #
        # @param name [Symbol] a unique identifier for a bootable component
        #
        # @see Lifecycle
        #
        # @return [self]
        #
        # @api public
        def boot(name, **opts, &block)
          if components.key?(name)
            raise DuplicatedComponentKeyError, <<-STR
              Bootable component #{name.inspect} was already registered
            STR
          end

          component =
            if opts[:from]
              boot_external(name, **opts, &block)
            else
              boot_local(name, **opts, &block)
            end

          booter.register_component component

          components[name] = component
        end
        deprecate :finalize, :boot

        # @api private
        def boot_external(identifier, from:, key: nil, namespace: nil, &block)
          System.providers[from].component(
            identifier, key: key, namespace: namespace, finalize: block, container: self
          )
        end

        # @api private
        def boot_local(identifier, namespace: nil, &block)
          Components::Bootable.new(
            identifier, container: self, namespace: namespace, &block
          )
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

        # Boots a specific component
        #
        # As a result, `init` and `start` lifecycle triggers are called
        #
        # @example
        #   MyApp.start(:persistence)
        #
        # @param name [Symbol] the name of a registered bootable component
        #
        # @return [self]
        #
        # @api public
        def start(name)
          booter.start(name)
          self
        end

        # Boots a specific component but calls only `init` lifecycle trigger
        #
        # This way of booting is useful in places where a heavy dependency is
        # needed but its started environment is not required
        #
        # @example
        #   MyApp.init(:persistence)
        #
        # @param [Symbol] name The name of a registered bootable component
        #
        # @return [self]
        #
        # @api public
        def init(name)
          booter.init(name)
          self
        end

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
        #   @param [String,Symbol] key Identifier
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
          @booter ||= config.booter.new(boot_paths)
        end

        # @api private
        def boot_paths
          config.bootable_dirs.map { |dir|
            dir = Pathname(dir)

            if dir.relative?
              root.join(dir)
            else
              dir
            end
          }
        end

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

          component = component(key)

          if component.bootable?
            booter.start(component)
            return self
          end

          booter.boot_dependency(component)
          return self if registered?(key)

          if component.file_exists?
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

          container.load_component(identifier.dequalified(import_namespace).key)

          importer.(import_namespace, container)
        end

        def component(identifier)
          if (bootable_component = booter.find_component(identifier))
            return bootable_component
          end

          # Find the first matching component from within the configured component dirs.
          # If no matching component is found, return a plain component instance with no
          # associated file path. This fallback is important because the component may
          # still be loadable via the manual registrar or an imported container.
          component_dirs.detect { |dir|
            if (component = dir.component_for_identifier(identifier))
              break component
            end
          } || Component.new(identifier)
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
