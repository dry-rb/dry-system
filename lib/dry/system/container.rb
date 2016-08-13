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
        def configure(&block)
          super(&block)
          load_paths!(config.core_dir)
          self
        end

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

        def finalize(name, &block)
          booter[name] = [self, block]
          self
        end

        def finalize!(&block)
          return self if frozen?

          yield(self) if block

          importer.finalize!
          booter.finalize!
          auto_registrar.finalize!

          freeze
        end

        def boot!(name)
          booter.boot!(name)
          self
        end

        def boot(name)
          booter.boot(name)
          self
        end

        def auto_register!(dir, &block)
          auto_registrar.(dir, &block)
          self
        end

        def component(key)
          Component.new(
            key,
            loader: config.loader,
            namespace: config.default_namespace,
            separator: config.namespace_separator
          )
        end

        def injector(options = {})
          Injector.new(self, options: options)
        end

        def require(*paths)
          paths.flat_map { |path|
            path.to_s.include?('*') ? Dir[root.join(path)] : root.join(path)
          }.each { |path|
            Kernel.require path.to_s
          }
        end

        def root
          config.root
        end

        def load_paths!(*dirs)
          dirs.map(&root.method(:join)).each do |path|
            next if load_paths.include?(path)
            load_paths << path
            $LOAD_PATH.unshift(path.to_s)
          end
          self
        end

        def load_paths
          @load_paths ||= []
        end

        def booter
          @booter ||= config.booter.new(root.join("#{config.core_dir}/boot"))
        end

        def auto_registrar
          @auto_registrar ||= config.auto_registrar.new(self)
        end

        def importer
          @importer ||= config.importer.new(self)
        end

        def require_component(component)
          return if key?(component.identifier)

          unless component.file_exists?(load_paths)
            raise FileNotFoundError, component
          end

          Kernel.require(component.path) && yield
        end

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

        def load_external_component(component)
          container = importer[component.namespace]
          container.load_component(component.identifier)
          importer.(component.namespace, container)
        end
      end
    end
  end
end
