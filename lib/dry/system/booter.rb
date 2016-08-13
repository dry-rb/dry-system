require 'dry/system/errors'
require 'dry/system/lifecycle'

module Dry
  module System
    class Booter
      attr_reader :path

      attr_reader :finalizers

      attr_reader :booted

      def initialize(path)
        @path = path
        @booted = {}
        @finalizers = {}
      end

      def []=(name, fn)
        @finalizers[name] = fn
        self
      end

      def [](name)
        @finalizers.fetch(name)
      end

      def finalize!
        Dir[boot_files].each do |path|
          boot!(File.basename(path, '.rb').to_sym)
        end
        freeze
      end

      def boot(name)
        Kernel.require(path.join(name.to_s))

        call(name) do |lifecycle|
          lifecycle.(:start)
          yield(lifecycle) if block_given?
        end

        self
      end

      def boot!(name)
        check_component_identifier(name)

        return self if booted.key?(name)

        boot(name) { |lifecycle| lifecycle.(:runtime) }
        booted[name] = true

        self
      end

      def call(name)
        container, finalizer = finalizers[name]

        if finalizer
          lifecycle = Lifecycle.new(container, &finalizer)
          yield(lifecycle) if block_given?
          lifecycle
        end
      end

      def boot_dependency(component)
        boot_file = component.boot_file(path)
        boot!(boot_file.basename('.*').to_s.to_sym) if boot_file.exist?
      end

      private

      def boot_files
        path.join('**/*.rb').to_s
      end

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
