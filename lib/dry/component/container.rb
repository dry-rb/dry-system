require 'pathname'
require 'inflecto'

require 'dry-configurable'
require 'dry-container'

require 'dry/component/injector'
require 'dry/component/loader'

module Dry
  module Component
    FileNotFoundError = Class.new(StandardError)

    class Container
      extend Dry::Configurable
      extend Dry::Container::Mixin

      setting :name
      setting :default_namespace
      setting :root, Pathname.pwd.freeze
      setting :core_dir, 'component'.freeze
      setting :auto_register
      setting :loader, Dry::Component::Loader

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
          if other < Component::Container
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

      def self.loader
        @loader ||= config.loader.new(config)
      end

      def self.injector(options = {})
        Injector.new(self, options: options)
      end

      def self.auto_register!(dir, &_block)
        dir_root = root.join(dir.to_s.split('/')[0])

        Dir["#{root}/#{dir}/**/*.rb"].each do |path|
          component_path = path.to_s.gsub("#{dir_root}/", '').gsub('.rb', '')
          loader.load(component_path).tap do |component|
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
        check_component_identifier!(name)

        return self unless booted?(name)

        boot(name)

        finalizers[name].tap do |finalizer|
          finalizer.() if finalizer
        end

        booted[name] = true

        self
      end

      def self.boot(name)
        require "#{config.core_dir}/boot/#{name}"
      end

      def self.booted?(name)
        !booted.key?(name)
      end

      def self.require(*paths)
        paths.flat_map { |path|
          path.to_s.include?('*') ? Dir[root.join(path)] : root.join(path)
        }.each { |path|
          Kernel.require path.to_s
        }
      end

      def self.load_component(key)
        return self if key?(key)

        component = loader.load(key)
        src_key = component.namespaces[0]

        if imports.key?(src_key)
          src_container = imports[src_key]

          src_container.load_component(
            (component.namespaces - [src_key]).map(&:to_s).join('.')
          )

          import_container(src_key, src_container)
        else
          begin
            require_component(component) do
              register(key) { component.instance }
            end
          rescue FileNotFoundError => e
            if config.default_namespace
              load_component("#{config.default_namespace}#{config.namespace_separator}#{component.identifier}")
            else
              raise e
            end
          end
        end

        self
      end

      def self.require_component(component, &block)
        path = load_paths.detect { |p| p.join(component.file).exist? }

        if path
          Kernel.require component.path
          yield(component) if block
        else
          raise FileNotFoundError, "could not resolve require file for #{component.identifier}"
        end
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

      private

      def self.import_container(ns, container)
        items = container._container.each_with_object({}) { |(key, item), res|
          res[[ns, key].join(config.namespace_separator)] = item
        }

        _container.update(items)
      end

      def self.auto_register
        Array(config.auto_register)
      end

      def self.auto_register?
        !auto_register.empty?
      end

      def self.check_component_identifier!(name)
        fail(
          ArgumentError,
          'component identifier must be a symbol'
        ) unless name.is_a?(Symbol)

        fail(
          ArgumentError,
          "component identifier +#{name}+ is invalid or boot file is missing"
        ) unless root.join("#{config.core_dir}/boot/#{name}.rb").exist?
      end
    end
  end
end
