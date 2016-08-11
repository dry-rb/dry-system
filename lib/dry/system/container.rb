require 'pathname'

require 'dry-configurable'
require 'dry-container'

require 'dry/system/errors'
require 'dry/system/injector'
require 'dry/system/loader'
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
      setting :auto_register
      setting :loader, Dry::System::Loader

      def self.configure(&block)
        super(&block)

        load_paths!(config.core_dir)

        self
      end

      def self.import(other)
        case other
        when Dry::Container::Namespace then super
        when Hash then imports.update(other)
        else
          if other < System::Container
            imports.update(other.config.name => other)
          end
        end
      end

      def self.finalize(name, &block)
        finalizers[name] = proc { block.(self) }
      end

      def self.finalize!(&_block)
        yield(self) if block_given?

        imports.each do |ns, container|
          import_container(ns, container.finalize!)
        end

        Dir[root.join("#{config.core_dir}/boot/**/*.rb")].each do |path|
          boot!(File.basename(path, '.rb').to_sym)
        end

        auto_register.each(&method(:auto_register!)) if auto_register?

        freeze
      end

      def self.component(key)
        Component.new(
          key,
          loader: config.loader,
          namespace: config.default_namespace,
          separator: config.namespace_separator
        )
      end

      def self.injector(options = {})
        Injector.new(self, options: options)
      end

      def self.auto_register!(dir, &_block)
        dir_root = root.join(dir.to_s.split('/')[0])

        Dir["#{root}/#{dir}/**/*.rb"].each do |path|
          path = path.to_s.sub("#{dir_root}/", '').sub(RB_EXT, EMPTY_STRING)

          component(path).tap do |component|
            next if key?(component.identifier)

            Kernel.require component.path

            if block_given?
              register(component.identifier, yield(component))
            else
              register(component.identifier) { component.instance }
            end
          end
        end

        self
      end

      def self.boot!(name)
        check_component_identifier(name)

        return self unless booted?(name)

        boot(name)

        finalizers[name].tap do |finalizer|
          finalizer.() if finalizer
        end

        booted[name] = true

        self
      end

      def self.boot(name)
        require "#{boot_path}/#{name}"
      end

      def self.boot_path
        root.join(config.core_dir).join('boot')
      end

      def self.booted?(name)
        !booted.key?(name)
      end

      def self.bootable_components
        Dir[boot_path.join('*.rb')]
          .map(&Kernel.method(:Pathname))
          .map { |file| file.basename('.*').to_s }
      end

      def self.require(*paths)
        paths.flat_map { |path|
          path.to_s.include?('*') ? Dir[root.join(path)] : root.join(path)
        }.each { |path|
          Kernel.require path.to_s
        }
      end

      def self.root
        config.root
      end

      def self.load_paths!(*dirs)
        dirs.map(&:to_s).each do |dir|
          path = root.join(dir)

          next if load_paths.include?(path)

          load_paths << path
          $LOAD_PATH.unshift(path.to_s)
        end

        self
      end

      def self.load_paths
        @load_paths ||= []
      end

      def self.booted
        @booted ||= {}
      end

      def self.finalizers
        @finalizers ||= {}
      end

      def self.imports
        @imports ||= {}
      end

      def self.load_component(key)
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

      def self.load_local_component(component, fallback = false)
        if component.bootable?(boot_path) || component.file_exists?(load_paths)
          boot_dependency(component) unless frozen?

          require_component(component) do
            register(component.identifier) { component.instance }
          end
        elsif !fallback
          load_local_component(component.prepend(config.default_namespace), true)
        else
          raise ComponentLoadError, component
        end
      end
      private_class_method :load_local_component

      def self.load_external_component(component)
        container = imports[component.namespace]
        container.load_component(component.identifier)
        import_container(component.namespace, container)
      end
      private_class_method :load_external_component

      def self.require_component(component, &block)
        return if keys.include?(component.identifier)

        path = load_paths.detect { |p| p.join(component.file).exist? }

        raise FileNotFoundError, component unless path

        Kernel.require component.path

        yield(component) if block
      end
      private_class_method :require_component

      def self.boot_dependency(component)
        boot_file = component.boot_file(boot_path)
        boot!(boot_file.basename('.*').to_s.to_sym) if boot_file.exist?
      end
      private_class_method :boot_dependency

      def self.import_container(ns, container)
        items = container._container.each_with_object({}) { |(key, item), res|
          res[[ns, key].join(config.namespace_separator)] = item
        }

        _container.update(items)
      end
      private_class_method :import_container

      def self.auto_register
        Array(config.auto_register)
      end
      private_class_method :auto_register

      def self.auto_register?
        !auto_register.empty?
      end
      private_class_method :auto_register?

      def self.check_component_identifier(name)
        unless name.is_a?(Symbol)
          raise InvalidComponentIdentifierTypeError, name
        end

        unless root.join("#{config.core_dir}/boot/#{name}.rb").exist?
          raise InvalidComponentIdentifierError, name
        end
      end
      private_class_method :check_component_identifier
    end
  end
end
