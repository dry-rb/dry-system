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
      attr_reader :path

      attr_reader :finalizers

      attr_reader :booted

      # @api private
      def initialize(path)
        @path = path
        @booted = {}
        @finalizers = {}
      end

      # @api private
      def []=(name, fn)
        @finalizers[name] = fn
        self
      end

      # @api private
      def finalize!
        Dir[boot_files].each do |path|
          start(File.basename(path, '.rb').to_sym)
        end
        freeze
      end

      # @api private
      def init(name)
        Kernel.require(path.join(name.to_s))

        call(name) do |lifecycle|
          lifecycle.(:init)
          yield(lifecycle) if block_given?
        end

        self
      end

      # @api private
      def start(name)
        check_component_identifier(name)

        return self if booted.key?(name)

        init(name) { |lifecycle| lifecycle.(:start) }
        booted[name] = true

        self
      end

      # @api private
      def call(name)
        container, finalizer = finalizers[name]

        raise ComponentFileMismatchError.new(name, registered_booted_keys) unless finalizer

        lifecycle = Lifecycle.new(container, &finalizer)
        yield(lifecycle) if block_given?
        lifecycle
      end

      # @api private
      def boot_dependency(component)
        boot_file = component.boot_file(path)
        start(boot_file.basename('.*').to_s.to_sym) if boot_file.exist?
      end

      private

      # @api private
      def registered_booted_keys
        finalizers.keys - booted.keys
      end

      # @api private
      def boot_files
        path.join('**/*.rb').to_s
      end

      # @api private
      def check_component_identifier(name)
        unless name.is_a?(Symbol)
          raise InvalidComponentIdentifierTypeError, name
        end

        unless path.join("#{name}.rb").exist?
          raise InvalidComponentIdentifierError, name
        end
      end
    end
  end
end
