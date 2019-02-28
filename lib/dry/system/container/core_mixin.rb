require 'dry/system/constants'
require 'dry/system/loader'
require 'dry/system/provider'
require 'dry/system/identified'

module Dry
  module System
    module Core
      module Mixin
        def self.extended(klass)
          klass.setting :name
          klass.setting(:default_namespace) { |namespace| namespace.to_s.split(DEFAULT_SEPARATOR).map(&:to_sym) }
          klass.setting(:root, Pathname.pwd.freeze) { |path| Pathname(path) }
          klass.setting :system_dir, 'system'.freeze
          klass.setting :inflector, Dry::Inflector.new
          klass.setting :loader, Dry::System::Loader
        end

        # @api public
        def resolve(key)
          load_identified(key) unless finalized?

          super
        end

        def configure(&block)
          super do |config|
            yield config

            load_paths!(config.system_dir)

            config.loader = Class.new(config.loader)
            config.loader.config.inflector = config.inflector
          end

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
        # @param [Array<String>] dirs
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

        # @api private
        def load_paths
          @load_paths ||= []
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
            path.to_s.include?('*') ? Dir[root.join(path)] : root.join(path)
          }.each { |path|
            require path.to_s
          }
        end

        # @api private
        def shutdown!
          hooks.trigger(:shutdown!)
          self
        end

        private

        # @api private
        def load_identified(key)
          return self if key?(key)

          load_missing(Identified.new(key, namespace: config.default_namespace))
        end

        def load_missing(identified)
          plugins.key_missing(identified)

          if key?(identified.identifier)
            self
          elsif !identified.namespace_prefixed?
            load_missing(identified.prepend(identified.namespace))
          else
            raise ComponentLoadError, identified
          end
        end
      end
    end
  end
end
