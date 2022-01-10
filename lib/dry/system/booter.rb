# frozen_string_literal: true

require "dry/system/provider"
require "dry/system/errors"
require "dry/system/constants"
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
      attr_reader :providers

      attr_reader :provider_paths

      # @api private
      def initialize(provider_paths)
        @providers = {}
        @provider_paths = provider_paths
      end

      # @api private
      def register_provider(provider)
        providers[provider.name] = provider
        self
      end

      # @api private
      def [](provider_name)
        providers[provider_name]
      end
      alias_method :provider, :[]

      # TODO: deprecate this as `boot_files`
      # TODO: leave a note in the documents as to why this is public (dry-rails)
      # Returns all provider files within the configured provider_paths
      #
      # Searches for files in the order of the configured provider_paths. In the case of multiple
      # identically-named boot files within different provider_paths, the file found first will be
      # returned, and other matching files will be discarded.
      #
      # @return [Array<Pathname>]
      # @api public
      def provider_files
        @provider_files ||= provider_paths.each_with_object([[], []]) { |path, (provider_files, loaded)|
          files = Dir["#{path}/#{RB_GLOB}"].sort

          files.each do |file|
            basename = File.basename(file)

            unless loaded.include?(basename)
              provider_files << Pathname(file)
              loaded << basename
            end
          end
        }.first
      end

      # Returns a provider if it can be found or loaded, otherwise nil
      #
      # @return [Dry::System::Provider, nil]
      #
      # @api private
      def find_provider(name)
        name = name.to_sym

        return providers[name] if providers.key?(name)

        return if finalized?

        require_provider_file(name)

        providers[name] if providers.key?(name)
      end

      # @api private
      def finalize!
        provider_files.each do |path|
          load_provider(path)
        end

        providers.values.each do |provider|
          start(provider)
        end

        freeze
      end

      # @api private
      def boot_dependency(component)
        if (provider = find_provider(component.root_key))
          start(provider.name)
        end
      end

      # @!method finalized?
      #   Returns true if the booter has been finalized
      #
      #   @return [Boolean]
      #   @api private
      alias_method :finalized?, :frozen?

      # @api private
      def shutdown
        providers.values.each do |provider|
          stop(provider)
        end
      end

      # @api private
      def prepare(name_or_provider)
        with_provider(name_or_provider) do |provider|
          provider.prepare
          self
        end
      end

      # @api private
      def start(name_or_provider)
        with_provider(name_or_provider) do |provider|
          provider.start
          self
        end
      end

      # @api private
      def stop(name_or_provider)
        with_provider(name_or_provider) do |provider|
          provider.stop
          self
        end
      end

      private

      def with_provider(id_or_provider)
        provider =
          case id_or_provider
          when Provider
            id_or_provider
          when Symbol
            require_provider_file(id_or_provider) unless providers.key?(id_or_provider)
            providers[id_or_provider]
          end

        raise ProviderNotFoundError, id_or_provider unless provider

        yield(provider)
      end

      def load_provider(path)
        name = Pathname(path).basename(RB_EXT).to_s.to_sym

        Kernel.require path unless providers.key?(name)

        self
      end

      def require_provider_file(name)
        provider_file = find_provider_file(name)

        Kernel.require provider_file if provider_file
      end

      def find_provider_file(name)
        provider_files.detect { |file| File.basename(file, RB_EXT) == name.to_s }
      end
    end
  end
end
