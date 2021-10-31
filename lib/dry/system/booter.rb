# frozen_string_literal: true

require "dry/system/components/bootable"
require "dry/system/errors"
require "dry/system/constants"
require "dry/system/lifecycle"
require "dry/system/booter/component_registry"
require "pathname"

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
      attr_reader :paths

      attr_reader :booted

      attr_reader :components

      # @api private
      def initialize(paths)
        @paths = paths
        @booted = []
        @components = ComponentRegistry.new
      end

      # @api private
      def register_component(component)
        components.register(component)
        self
      end

      # Returns a bootable component if it can be found or loaded, otherwise nil
      #
      # @return [Dry::System::Components::Bootable, nil]
      # @api private
      def find_component(name)
        name = name.to_sym

        return components[name] if components.exists?(name)

        return if finalized?

        require_boot_file(name)

        components[name] if components.exists?(name)
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

      # @!method finalized?
      #   Returns true if the booter has been finalized
      #
      #   @return [Boolean]
      #   @api private
      alias_method :finalized?, :frozen?

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
          raise ComponentNotStartedError, name_or_component unless booted.include?(component)

          component.stop
          booted.delete(component)

          yield if block_given?
        end
      end

      # @api private
      def call(name_or_component)
        with_component(name_or_component) do |component|
          raise ComponentFileMismatchError, name unless component

          yield(component) if block_given?

          component
        end
      end

      # @api private
      def boot_dependency(component)
        if (component = find_component(component.root_key))
          start(component)
        end
      end

      # Returns all boot files within the configured paths
      #
      # Searches for files in the order of the configured paths. In the case of multiple
      # identically-named boot files within different paths, the file found first will be
      # returned, and other matching files will be discarded.
      #
      # @return [Array<Pathname>]
      # @api public
      def boot_files
        @boot_files ||= paths.each_with_object([[], []]) { |path, (boot_files, loaded)|
          files = Dir["#{path}/#{RB_GLOB}"].sort

          files.each do |file|
            basename = File.basename(file)

            unless loaded.include?(basename)
              boot_files << Pathname(file)
              loaded << basename
            end
          end
        }.first
      end

      private

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

      def load_component(path)
        name = Pathname(path).basename(RB_EXT).to_s.to_sym

        Kernel.require path unless components.exists?(name)

        self
      end

      def require_boot_file(name)
        boot_file = find_boot_file(name)

        Kernel.require boot_file if boot_file
      end

      def find_boot_file(name)
        boot_files.detect { |file| File.basename(file, RB_EXT) == name.to_s }
      end
    end
  end
end
