require 'pathname'

require 'dry-auto_inject'
require 'dry-configurable'
require 'dry-container'

require 'dry/system/errors'
require 'dry/system/loader'
require 'dry/system/booter'
require 'dry/system/auto_registrar'
require 'dry/system/manual_registrar'
require 'dry/system/importer'
require 'dry/system/component'
require 'dry/system/constants'

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
    # file. Components which specify their dependencies using. Import module can
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
    # * `:system_dir` - directory name relative to root, where bootable components
    #                 can be defined in `boot` dir this defaults to `system`
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
    #     load_paths!('lib)
    #   end
    #
    # @api public
    class Container
      extend Dry::Configurable
      extend Dry::Container::Mixin

      setting :name
      setting :default_namespace
      setting(:root, Pathname.pwd.freeze) { |path| Pathname(path) }
      setting :system_dir, 'system'.freeze
      setting :registrations_dir, 'container'.freeze
      setting :auto_register, []
      setting :loader, Dry::System::Loader
      setting :booter, Dry::System::Booter
      setting :auto_registrar, Dry::System::AutoRegistrar
      setting :manual_registrar, Dry::System::ManualRegistrar
      setting :importer, Dry::System::Importer

      class << self
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
          super(&block)
          load_paths!(config.system_dir)
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
        # @param other [Hash,Dry::Container::Namespace]
        #
        # @api public
        def import(other)
          case other
          when Hash then importer.register(other)
          when Dry::Container::Namespace then super
          else
            raise ArgumentError, "+other+ must be a hash of names and systems, or a Dry::Container namespace"
          end
        end

        # Registers finalization function for a bootable component
        #
        # By convention, boot files for components should be placed in
        # `%{system_dir}/boot` and they will be loaded on demand when components
        # are loaded in isolation, or during finalization process.
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
        #   MyApp.finalize(:db) do |container|
        #     require 'db'
        #
        #     container.register(:db, DB.new)
        #   end
        #
        #   # system/boot/db.rb
        #   #
        #   # Component registration with lifecycle triggers
        #   MyApp.finalize(:db) do |container|
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
        #   MyApp.finalize(:db) do |container|
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
        def finalize(name, &block)
          booter[name] = [self, block]
          self
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
        #   # If you need last-moment adjustements just before the finalization
        #   # you can pass a block and do it there
        #   MyApp.finalize! do |container|
        #     # stuff that only needs to happen for finalization
        #   end
        #
        # @return [self] frozen container
        #
        # @api public
        def finalize!(&block)
          return self if frozen?

          yield(self) if block

          importer.finalize!
          booter.finalize!
          manual_registrar.finalize!
          auto_registrar.finalize!

          freeze
        end

        # Boots a specific component
        #
        # As a result, `init` and `start` lifecycle triggers are called
        #
        # @example
        #   MyApp.boot!(:persistence)
        #
        # @param name [Symbol] the name of a registered bootable component
        #
        # @return [self]
        #
        # @api public
        def boot!(name)
          booter.boot!(name)
          self
        end

        # Boots a specific component but calls only `init` lifecycle trigger
        #
        # This way of booting is useful in places where a heavy dependency is
        # needed but its started environment is not required
        #
        # @example
        #   MyApp.boot(:persistence)
        #
        # @param [Symbol] name The name of a registered bootable component
        #
        # @return [self]
        #
        # @api public
        def boot(name)
          booter.boot(name)
          self
        end

        # Sets load paths relative to the container's root dir
        #
        # @example
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       # ...
        #     end
        #
        #     load_paths!('lib')
        #   end
        #
        # @param [Array<String>] *dirs
        #
        # @return [self]
        #
        # @api public
        def load_paths!(*dirs)
          dirs.map(&root.method(:join)).each do |path|
            next if load_paths.include?(path)
            load_paths << path
            $LOAD_PATH.unshift(path.to_s)
          end
          self
        end

        # @api public
        def load_registrations!(name)
          manual_registrar.(name)
          self
        end

        # Auto-registers components from the provided directory
        #
        # Typically you want to configure auto_register directories, and it will
        # work automatically. Use this method in cases where you want to have an
        # explicit way where some components are auto-registered, or if you want
        # to exclude some components from been auto-registered
        #
        # @example
        #   class MyApp < Dry::System::Container
        #     configure do |config|
        #       # ...
        #     end
        #
        #     # with a dir
        #     auto_register!('lib/core')
        #
        #     # with a dir and a custom registration block
        #     auto_register!('lib/core') do |config|
        #       config.instance do |component|
        #         # custom way of initializing a component
        #       end
        #
        #       config.exclude do |component|
        #         # return true to exclude component from auto-registration
        #       end
        #     end
        #   end
        #
        # @param [String] dir The dir name relative to the root dir
        #
        # @yield AutoRegistrar::Configuration
        # @see AutoRegistrar::Configuration
        #
        # @return [self]
        #
        # @api public
        def auto_register!(dir, &block)
          auto_registrar.(dir, &block)
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
        def injector(options = {})
          Dry::AutoInject(self, options)
        end

        # Requires one or more files relative to the container's root
        #
        # @example
        #   # sinle file
        #   MyApp.require('lib/core')
        #
        #   # glob
        #   MyApp.require('lib/**/*')
        #
        # @param *paths [Array<String>] one or more paths, supports globs too
        #
        # @api public
        def require(*paths)
          paths.flat_map { |path|
            path.to_s.include?('*') ? Dir[root.join(path)] : root.join(path)
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
          load_component(key) unless frozen?

          super
        end

        # @api private
        def load_paths
          @load_paths ||= []
        end

        # @api private
        def booter
          @booter ||= config.booter.new(root.join("#{config.system_dir}/boot"))
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
        def component(key, **options)
          Component.new(
            key,
            loader: config.loader,
            namespace: config.default_namespace,
            separator: config.namespace_separator,
            **options,
          )
        end

        # @api private
        def require_component(component)
          return if key?(component.identifier)

          unless component.file_exists?(load_paths)
            raise FileNotFoundError, component
          end

          Kernel.require(component.path)

          yield
        end

        # @api private
        def load_component(key)
          return self if key?(key)

          component(key).tap do |component|
            root_key = component.root_key

            if importer.key?(root_key)
              load_external_component(component.namespaced(root_key))
            else
              load_local_component(component)
            end
          end

          self
        end

        private

        # @api private
        def load_local_component(component, default_namespace_fallback = false)
          if component.bootable?(booter.path) || component.file_exists?(load_paths)
            booter.boot_dependency(component) unless frozen?

            require_component(component) do
              register(component.identifier) { component.instance }
            end
          elsif !default_namespace_fallback
            load_local_component(component.prepend(config.default_namespace), true)
          elsif manual_registrar.file_exists?(component)
            manual_registrar.(component)
          else
            raise ComponentLoadError, component
          end
        end

        # @api private
        def load_external_component(component)
          container = importer[component.namespace]
          container.load_component(component.identifier)
          importer.(component.namespace, container)
        end
      end
    end
  end
end
