require 'dry/system/components/bootable'
require 'dry/system/errors'
require 'dry/system/lifecycle'

module Dry
  module System
    # Default booter implementation
    #
    # This is currently configured by default for every System::Container.
    # Booter objects are responsible for loading system/boot files and expose
    # an API for calling lifecycle triggers.
    #
    # @api private
    class Booter
      class LifecycleContainer
        include Container::Mixin
      end

      attr_reader :path

      attr_reader :booted

      attr_reader :components

      attr_reader :listeners

      class ComponentRegistry
        include Enumerable

        attr_reader :components

        def initialize
          @components = []
        end

        def each(&block)
          components.each(&block)
        end

        def register(component)
          @components << component
        end

        def exists?(name)
          components.any? { |component| component.identifier == name }
        end

        def [](name)
          component = components.detect { |component| component.identifier == name }

          if component
            component.ensure_valid_boot_file
            component
          else
            raise InvalidComponentIdentifierError, name
          end
        end
      end

      # @api private
      def initialize(path)
        @path = path
        @booted = []
        @components = ComponentRegistry.new
        @listeners = Hash.new { |h, k| h[k] = {} }
      end

      # @api private
      def register_component(*args)
        if args.size > 1
          name, container, opts, fn = args
          components.register(Components::Bootable.new(name, fn, opts.merge(container: container)))
        else
          components.register(args[0])
        end

        self
      end

      # @api private
      def load_component(path)
        identifier = Pathname(path).basename('.rb').to_s.to_sym

        unless components.exists?(identifier)
          require path
        end

        self
      end

      # @api private
      def finalize!
        boot_files.each do |path|
          load_component(path)
        end

        components.each do |component|
          start(component)
        end
        freeze
      end

      # @api private
      def init(name_or_component)
        with_component(name_or_component) do |component|
          call(component) do |lifecycle, container|
            lifecycle.(:init)

            if listener = listeners[component.key][:init]
              listener.()
            end

            yield(lifecycle, container) if block_given?
          end

          self
        end
      end

      # @api private
      def start(name_or_component)
        with_component(name_or_component) do |component|
          return self if booted.include?(component)

          init(name_or_component) do |lifecycle, container|
            lifecycle.(:start)

            if lifecycle.container != container
              container.register(component.key, lifecycle.container[component.identifier])
            end
          end

          booted << component

          self
        end
      end

      # @api private
      def call(name_or_component)
        with_component(name_or_component) do |component|
          lf_container = component.external? ? lifecycle_container : component.container

          unless component
            raise ComponentFileMismatchError.new(name, registered_booted_keys)
          end

          lifecycle = Lifecycle.new(lf_container, &component)
          yield(lifecycle, component.container) if block_given?
          lifecycle
        end
      end

      # @api private
      def lifecycle_container
        LifecycleContainer.new
      end

      # @api private
      def on(spec, &block)
        identifier, step = spec.to_a.flatten(1)
        listeners[identifier][step] = block

        self
      end

      # @api private
      def with_component(id_or_component)
        component =
          case id_or_component
          when Symbol
            require_boot_file(id_or_component) unless components.exists?(id_or_component)
            components[id_or_component]
          when Components::Bootable
            id_or_component
          end

        raise InvalidComponentError, id_or_component unless component

        yield(component)
      end

      # @api private
      def require_boot_file(identifier)
        boot_file = boot_files.detect { |path| Pathname(path).basename('.rb').to_s == identifier.to_s }
        require boot_file if boot_file
      end

      # @api private
      def boot_files
        Dir["#{path}/**/*.rb"]
      end

      # @api private
      def boot_dependency(component)
        boot_file = component.boot_file(path)
        start(boot_file.basename('.*').to_s.to_sym) if boot_file.exist?
      end
    end
  end
end
