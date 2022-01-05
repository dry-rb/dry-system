# frozen_string_literal: true

require "dry/system/provider"
require "dry/system/errors"
require "dry/system/constants"
require "dry/system/lifecycle"
require "dry/system/booter/provider_registry"
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

      attr_reader :providers

      # @api private
      def initialize(paths)
        @paths = paths
        @booted = []
        @providers = ProviderRegistry.new
      end

      # @api private
      def register_provider(provider)
        providers.register(provider)
        self
      end

      # TODO: update docs

      # Returns a bootable component if it can be found or loaded, otherwise nil
      #
      # @return [Dry::System::Provider, nil]
      # @api private
      def find_provider(name)
        name = name.to_sym

        return providers[name] if providers.exists?(name)

        return if finalized?

        require_boot_file(name)

        providers[name] if providers.exists?(name)
      end

      # @api private
      def finalize!
        boot_files.each do |path|
          load_provider(path)
        end

        providers.each do |provider|
          start(provider)
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
        providers.each do |provider|
          next unless booted.include?(provider)

          stop(provider)
        end
      end

      # @api private
      def init(name_or_provider)
        with_provider(name_or_provider) do |provider|
          call(provider) do
            provider.init.finalize
            yield if block_given?
          end

          self
        end
      end

      # @api private
      def start(name_or_provider)
        with_provider(name_or_provider) do |provider|
          return self if booted.include?(provider)

          init(name_or_provider) do
            provider.start
          end

          booted << provider.finalize

          self
        end
      end

      # @api private
      def stop(name_or_provider)
        call(name_or_provider) do |provider|
          raise ComponentNotStartedError, name_or_provider unless booted.include?(provider) # TODO: update "ComponentFileMismatchError" name

          provider.stop
          booted.delete(provider)

          yield if block_given?
        end
      end

      # @api private
      def call(name_or_provider)
        with_provider(name_or_provider) do |provider|
          raise ComponentFileMismatchError, name unless provider # TODO: update "ComponentFileMismatchError" name

          yield(provider) if block_given?

          provider
        end
      end

      # @api private
      def boot_dependency(component)
        if (provider = find_provider(component.root_key))
          start(provider)
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

      def with_provider(id_or_provider)
        provider =
          case id_or_provider
          when Symbol
            require_boot_file(id_or_provider) unless providers.exists?(id_or_provider)
            providers[id_or_provider]
          when Provider
            id_or_provider
          end

        raise InvalidComponentError, id_or_provider unless provider # TODO: update error name

        yield(provider)
      end

      def load_provider(path)
        name = Pathname(path).basename(RB_EXT).to_s.to_sym

        Kernel.require path unless providers.exists?(name)

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
