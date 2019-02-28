require 'pathname'

require 'dry-container'
require 'dry-auto_inject'

require 'dry/system/hooks'
require 'dry/system/plugins/mixin'

module Dry
  module System
    # Abstract container class
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
    # component which has init/start/stop lifecycle, defined in a boot
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
    #     load_paths!('lib')
    #   end
    #
    # @api public
    class Base
      extend Dry::Container::Mixin

      class << self
        def hooks
          @hooks ||= Hooks.new
        end

        def plugins
          @plugins ||= Plugins::Manager.new(self)
        end

        def use(plugin)
          plugins.use(plugin)
        end

        def inherited(klass)
          klass.instance_variable_set(:@hooks, Hooks.new)
          klass.instance_variable_set(:@plugins, plugins.clone)
          klass.plugins.container = klass

          super
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
          hooks.subscribe(plugins)
          plugins.start!
          super(&block)
          hooks.trigger(:configure, :after)
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

          hooks.trigger(:finalize)

          yield(self) if block

          @__finalized__ = true
          self.freeze if freeze

          self
        end

        # Return if a container was finalized
        #
        # @return [TrueClass, FalseClass]
        #
        # @api public
        def finalized?
          @__finalized__.equal?(true)
        end
      end
    end
  end
end
