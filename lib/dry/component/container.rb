require 'inflecto'
require 'dry-container'
require 'dry-auto_inject'

require 'dry/component/loader'
require 'dry/component/config'

module Dry
  module Component
    class Container
      extend Dry::Container::Mixin

      setting :env
      setting :root, Pathname.pwd.freeze
      setting :auto_register
      setting :app

      def self.configure(env = config.env, &block)
        if !configured?
          super() do |config|
            app_config = Config.load(root, env)
            config.app = app_config if app_config
          end

          load_paths!('core')

          @_configured = true
        end

        yield(self)

        self
      end

      def self.finalize(name, &block)
        finalizers[name] = block
      end

      def self.configured?
        @_configured
      end

      def self.finalize!(&block)
        yield(self) if block

        Dir[root.join('core/boot/**/*.rb')].each do |path|
          boot!(File.basename(path, '.rb').to_sym)
        end

        if config.auto_register
          Array(config.auto_register).each(&method(:auto_register!))
        end

        freeze
      end

      def self.import_module
        auto_inject = Dry::AutoInject(self)

        -> *keys {
          keys.each { |key| load_component(key) unless key?(key) }
          auto_inject[*keys]
        }
      end

      def self.auto_register!(dir, &block)
        dir_root = root.join(dir.to_s.split('/')[0])

        Dir["#{root}/#{dir}/**/*.rb"].each do |path|
          component_path = path.to_s.gsub("#{dir_root}/", '').gsub('.rb', '')
          component = Component.Loader(component_path)

          next if key?(component.identifier)

          Kernel.require component.path

          if block
            register(component.identifier, yield(component.constant))
          else
            register(component.identifier) { component.instance }
          end
        end

        self
      end

      def self.boot!(name)
        unless name.is_a?(Symbol)
          raise ArgumentError, 'component identifier must be a symbol'
        end

        unless root.join("core/boot/#{name}.rb").exist?
          raise ArgumentError, "component identifier +#{name}+ is invalid or boot file is missing"
        end

        return self unless boot?(name)

        boot(name)

        finalizer = finalizers[name]
        finalizer.() if finalizer

        booted[name] = true

        self
      end

      def self.boot(name)
        require "core/boot/#{name}.rb"
      end

      def self.boot?(name)
        ! booted.key?(name)
      end

      def self.require(*paths)
        paths
          .flat_map { |path|
          path.include?('*') ? Dir[root.join(path)] : root.join(path)
        }
          .each { |path|
          Kernel.require path.to_s
        }
      end

      def self.load_component(key)
        require_component(key) { |klass| register(key) { klass.new } }
      end

      def self.require_component(key, &block)
        component = Component.Loader(key)
        path = load_paths.detect { |p| p.join(component.file).exist? }

        if path
          Kernel.require component.path
          yield(component.constant) if block
        else
          raise ArgumentError, "could not resolve require file for #{key}"
        end
      end

      def self.root
        config.root
      end

      def self.load_paths!(*dirs)
        dirs.map(&:to_s).each do |dir|
          path = root.join(dir)
          load_paths << path
          $LOAD_PATH.unshift(path.to_s)
        end
        self
      end

      def self.load_paths
        @_load_paths ||= []
      end

      def self.booted
        @_booted ||= {}
      end

      def self.finalizers
        @_finalizers ||= {}
      end
    end
  end
end
