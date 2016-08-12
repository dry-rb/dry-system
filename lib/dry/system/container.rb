require 'pathname'

require 'dry-configurable'
require 'dry-container'

require 'dry/system/errors'
require 'dry/system/injector'
require 'dry/system/loader'
require 'dry/system/booter'
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

      class << self
        def configure(&block)
          super(&block)
          load_paths!(config.core_dir)
          self
        end

        def import(other)
          case other
          when Dry::Container::Namespace then super
          when Hash then imports.update(other)
          else
            if other < System::Container
              imports.update(other.config.name => other)
            end
          end
        end

        def finalize(name, &block)
          booter[name] = proc { block.(self) }
          self
        end

        def finalize!(&_block)
          yield(self) if block_given?

          imports.each do |ns, container|
            import_container(ns, container.finalize!)
          end

          booter.finalize!
          Array(config.auto_register).each(&method(:auto_register!))

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

        def auto_register!(dir, &block)
          dir_root = root.join(dir.to_s.split('/')[0])

          Dir["#{root}/#{dir}/**/*.rb"].each do |path|
            path = path.to_s.sub("#{dir_root}/", '').sub(RB_EXT, EMPTY_STRING)

            component(path).tap do |component|
              next if key?(component.identifier)

              Kernel.require component.path

              if block
                register(component.identifier, yield(component))
              else
                register(component.identifier) { component.instance }
              end
            end
          end

          self
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

        def imports
          @imports ||= {}
        end

        def booter
          @booter ||= config.booter.new(root.join("#{config.core_dir}/boot"))
        end

        def load_component(key)
          return self if key?(key)

          component(key).tap do |component|
            src_key = component.root_key

            if imports.key?(src_key)
              load_external_component(component.namespaced(src_key))
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
          container = imports[component.namespace]
          container.load_component(component.identifier)
          import_container(component.namespace, container)
        end

        def require_component(component, &block)
          return if key?(component.identifier)

          path = load_paths.detect { |p| p.join(component.file).exist? }

          raise FileNotFoundError, component unless path

          Kernel.require component.path

          yield(component) if block
        end

        def import_container(ns, container)
          items = container._container.each_with_object({}) { |(key, item), res|
            res[[ns, key].join(config.namespace_separator)] = item
          }

          _container.update(items)
        end
      end
    end
  end
end
