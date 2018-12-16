require 'dry/system/components/bootable'
require 'dry/system/errors'
require 'dry/system/constants'
require 'dry/system/lifecycle'
require 'dry/system/booter/component_registry'

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
      attr_reader :path

      attr_reader :booted

      attr_reader :components

      # @api private
      def initialize(path)
        @path = path
        @booted = []
        @components = ComponentRegistry.new
      end

      # @api private
      def bootable?(component)
        boot_file(component).exist?
      end

      # @api private
      def boot_file(name)
        name = name.respond_to?(:root_key) ? name.root_key.to_s : name

        path.join("#{name}#{RB_EXT}")
      end

      # @api private
      def register_component(component)
        components.register(component)
        self
      end

      # @api private
      def load_component(path)
        identifier = Pathname(path).basename(RB_EXT).to_s.to_sym

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
      def shutdown
        components.each do |component|
          next unless booted.include?(component)

          stop(component)
        end
      end

      # @api private
      def init(name_or_component)
        with_component(name_or_component) do |component|
          call(component) do
            component.init.finalize
            yield if block_given?
          end

          self
        end
      end

      # @api private
      def start(name_or_component)
        with_component(name_or_component) do |component|
          return self if booted.include?(component)

          init(name_or_component) do
            component.start
          end

          booted << component.finalize

          self
        end
      end

      # @api private
      def stop(name_or_component)
        call(name_or_component) do |component|
          raise ComponentNotStartedError.new(name_or_component) unless booted.include?(component)

          component.stop
          booted.delete(component)

          yield if block_given?
        end
      end

      # @api private
      def call(name_or_component)
        with_component(name_or_component) do |component|
          unless component
            raise ComponentFileMismatchError.new(name, registered_booted_keys)
          end

          yield(component) if block_given?

          component
        end
      end

      # @api private
      def lifecycle_container(container)
        LifecycleContainer.new(container)
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
        boot_file = boot_files.detect { |path| Pathname(path).basename(RB_EXT).to_s == identifier.to_s }
        require boot_file if boot_file
      end

      # @api private
      def boot_files
        Dir["#{path}/**/#{RB_GLOB}"]
      end

      # @api private
      def boot_dependency(component)
        boot_file = boot_file(component)
        start(boot_file.basename('.*').to_s.to_sym) if boot_file.exist?
      end
    end
  end
end
