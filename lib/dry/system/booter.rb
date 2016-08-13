require 'dry/system/errors'
require 'dry/system/booter/dsl'

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
        self
      end

      def boot!(name)
        check_component_identifier(name)

        return self if booted.key?(name)

        boot(name)
        call(name)
        booted[name] = true

        self
      end

      def call(name)
        finalizers[name].tap do |(container, finalizer)|
          DSL.new(container, &finalizer) if finalizer
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
