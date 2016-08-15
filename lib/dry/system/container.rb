require 'pathname'

require 'dry-configurable'
require 'dry-container'

require 'dry/system/errors'
require 'dry/system/injector'
require 'dry/system/loader'
require 'dry/system/booter'
require 'dry/system/auto_registrar'
require 'dry/system/importer'
require 'dry/system/component'
require 'dry/system/constants'

module Dry
  module System
    # Abstract container class to inherit from
    #
    # Container class is treated as a global registry with all system components.
    # Container can also import dependencies from other containers, which is useful
    # in complex systems that are split into sub-systems.
    #
    # Container can be finalized, which triggers loading of all the defined components
    # within a system, after finalization it becomes frozen. This typically happens in cases
    # like booting a web application.
    #
    # Before finalization, Container can lazy-load components on demand. A component can be
    # a simple class defined in a single file, or a complex component which has start/init/stop
    # lifecycle, and it's defined in a boot file. Components which specify their dependencies using
    # Import module can be safely required in complete isolation, and Container will resolve and load
    # these dependencies automatically.
    #
    # Furthermore, Container supports auto-registering components based on dir/file naming conventions.
    # This reduces a lot of boilerplate code as all you have to do is to put your classes under configured
    # directories and their instances will be automatically registered within a container.
    #
    # Every container needs to be configured with following settings:
    #
    #   * `:name` - a unique container identifier
    #   * `:root` - a system root directory (defaults to `pwd`)
    #   * `:core_dir` - directory name relative to root, where bootable components can be defined in `boot` dir
    #                   this defaults to `component`
    #
    # @example
    #   class MyApp < Dry::System::Container
    #     configure do |config|
    #       config.name = :my_app
    #     end
    #
    #     # this will configure $LOAD_PATH to include your `lib` dir
    #     load_paths!('lib)
    #
    #     # this will auto-register classes from 'lib/components'. ie if you add `lib/components/repo.rb`
    #     # which defines `Repo` class, then it's instance will be automatically available as `MyApp['repo']`
    #     auto_register!('lib/components')
    #   end
    #
    # @api public
    class Container
      extend Dry::Configurable
      extend Dry::Container::Mixin

      setting :name
      setting :default_namespace
      setting :root, Pathname.pwd.freeze
      setting :core_dir, 'component'.freeze
      setting :auto_register, []
      setting :loader, Dry::System::Loader
      setting :booter, Dry::System::Booter
      setting :auto_registrar, Dry::System::AutoRegistrar
      setting :importer, Dry::System::Importer

      class << self
        # Configures the container
        #
        # @return [self]
        #
        # @api public
        def configure(&block)
          super(&block)
          load_paths!(config.core_dir)
          self
        end

        # Registers another container for import
        #
        # @param other [Hash,Dry::Container::Namespace,Dry::System::Container]
        #
        # @api public
        def import(other)
          case other
          when Hash then importer.register(other)
          when Dry::Container::Namespace then super
          else
            if other < System::Container
              importer.register(other.config.name => other)
            end
          end
        end

        # Registers finalization function for a bootable component
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
        # This triggers importing components from other containers, booting registered components
        # and auto-registering components. It should be called only in places where you want to
        # finalize your system as a whole, ie when booting a web application
        #
        # @return [self]
        #
        # @api public
        def finalize!(&block)
          return self if frozen?

          yield(self) if block

          importer.finalize!
          booter.finalize!
          auto_registrar.finalize!

          freeze
        end

        # Boots a specific component
        #
        # As a result, `start` and `init` lifecycle triggers are called
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

        # Boots a specific component but calls only `start` lifecycle trigger
        #
        # This way of booting is useful in places where a heavy dependency is
        # needed but its init environment is not required
        #
        # @param name [Symbol] the name of a registered bootable component
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
        # @param *dirs [Array<String>]
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

        # Auto-registers components from the provided directory
        #
        # The directory must be relative to the configured root path
        #
        # @param dir [String]
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
        # @param options [Hash] injector options
        #
        # @api public
        def injector(options = {})
          Injector.new(self, options: options)
        end

        # Requires one or more files relative to the container's root
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
        # @return [Pathname]
        #
        # @api public
        def root
          config.root
        end

        # @api private
        def load_paths
          @load_paths ||= []
        end

        # @api private
        def booter
          @booter ||= config.booter.new(root.join("#{config.core_dir}/boot"))
        end

        # @api private
        def auto_registrar
          @auto_registrar ||= config.auto_registrar.new(self)
        end

        # @api private
        def importer
          @importer ||= config.importer.new(self)
        end

        # @api private
        def component(key)
          Component.new(
            key,
            loader: config.loader,
            namespace: config.default_namespace,
            separator: config.namespace_separator
          )
        end

        # @api private
        def require_component(component)
          return if key?(component.identifier)

          unless component.file_exists?(load_paths)
            raise FileNotFoundError, component
          end

          Kernel.require(component.path) && yield
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
        def load_local_component(component, fallback = false)
          if component.bootable?(booter.path) || component.file_exists?(load_paths)
            booter.boot_dependency(component) unless frozen?

            require_component(component) do
              register(component.identifier) { component.instance }
            end
          elsif !fallback
            load_local_component(component.prepend(config.default_namespace), true)
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
