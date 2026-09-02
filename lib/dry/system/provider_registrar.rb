# frozen_string_literal: true

require "pathname"

require "dry/system/errors"
require "dry/system/constants"

module Dry
  module System
    # Default provider registrar implementation
    #
    # This is currently configured by default for every Dry::System::Container. The
    # provider registrar is responsible for loading provider files and exposing an API for
    # running the provider lifecycle steps.
    #
    # @api public
    # @since 1.1.0
    class ProviderRegistrar
      # @api private
      attr_reader :providers

      # @api private
      attr_reader :container

      # Returns the container exposed to providers as `target_container`.
      #
      # @return [Dry::System::Container]
      #
      # @api public
      # @since 1.1.0
      alias_method :target_container, :container

      # @api private
      def initialize(container)
        @providers = {}
        @container = container
        @loaded = Set.new
      end

      # @api private
      def freeze
        providers.freeze
        super
      end

      # rubocop:disable Metrics/PerceivedComplexity

      # @see Container.register_provider
      # @api private
      def register_provider(name, from: nil, source: nil, if: true, **provider_options, &)
        raise ProviderAlreadyRegisteredError, name if providers.key?(name)

        if from && source.is_a?(Class)
          raise ArgumentError, "You must supply a block when using a provider source"
        end

        if block_given? && source.is_a?(Class)
          raise ArgumentError, "You must supply only a `source:` option or a block, not both"
        end

        return self unless binding.local_variable_get(:if)

        provider =
          if from
            build_provider_from_source(
              name,
              source: source || name,
              group: from,
              options: provider_options,
              &
            )
          else
            build_provider(
              name,
              source: source,
              options: provider_options,
              &
            )
          end

        providers[provider.name] = provider

        self
      end

      # rubocop:enable Metrics/PerceivedComplexity

      # Returns a provider if it can be found or loaded, otherwise nil
      #
      # @return [Dry::System::Provider, nil]
      #
      # @api public
      def [](provider_name)
        provider_name = provider_name.to_sym

        if (provider = providers[provider_name])
          return provider
        end

        return if finalized?

        require_provider_file(provider_name)

        providers[provider_name]
      end

      # @api public
      alias_method :find_and_load_provider, :[]

      # @api private
      def key?(provider_name)
        providers.key?(provider_name)
      end

      # Returns all provider files within the configured provider_paths.
      #
      # Searches for files in the order of the configured provider_paths. In the case of multiple
      # identically-named boot files within different provider_paths, the file found first will be
      # returned, and other matching files will be discarded.
      #
      # This method is public to allow other tools extending dry-system (like dry-rails)
      # to access a canonical list of real, in-use provider files.
      #
      # @see Container.provider_paths
      #
      # @return [Array<Pathname>]
      # @api public
      def provider_files
        @provider_files ||= provider_paths.each_with_object([[], []]) { |path, (provider_files, loaded)|
          files = ::Dir["#{path}/#{RB_GLOB}"]

          files.each do |file|
            basename = ::File.basename(file)

            unless loaded.include?(basename)
              provider_files << Pathname(file)
              loaded << basename
            end
          end
        }.first
      end

      # Extension point for subclasses to customize their
      # provider source superclass. Expected to be a subclass
      # of Dry::System::Provider::Source
      #
      # @api public
      # @since 1.1.0
      def provider_source_class = Dry::System::Provider::Source

      # Extension point for subclasses to customize initialization
      # params for provider_source_class
      #
      # @api public
      # @since 1.1.0
      def provider_source_options = {}

      # @api private
      def finalize!
        provider_files.each do |path|
          load_provider(path)
        end

        providers.each_value(&:start)

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
        providers.each_value(&:stop)
        self
      end

      # @api private
      def prepare(provider_name)
        with_provider(provider_name, &:prepare)
        self
      end

      # @api private
      def start(provider_name)
        with_provider(provider_name, &:start)
        self
      end

      # @api private
      def stop(provider_name)
        with_provider(provider_name, &:stop)
        self
      end

      private

      # @api private
      def provider_paths
        provider_dirs = container.config.provider_dirs

        provider_dirs.map { |dir|
          dir = Pathname(dir)

          if dir.relative?
            container.root.join(dir)
          else
            dir
          end
        }
      end

      def build_provider(name, options:, source: nil, &)
        source_class = source || Provider::Source.for(
          name: name,
          superclass: provider_source_class,
          &
        )

        source_options =
          if source_class < provider_source_class
            provider_source_options
          else
            {}
          end

        Provider.new(
          **options,
          name: name,
          target_container: target_container,
          source_class: source_class,
          source_options: source_options
        )
      end

      def build_provider_from_source(name, source:, group:, options:, &)
        provider_source = System.provider_sources.resolve(name: source, group: group)

        source_options =
          if provider_source.source <= provider_source_class
            provider_source_options
          else
            {}
          end

        Provider.new(
          **provider_source.provider_options,
          **options,
          name: name,
          target_container: target_container,
          source_class: provider_source.source,
          source_options: source_options,
          &
        )
      end

      def with_provider(provider_name)
        require_provider_file(provider_name) unless providers.key?(provider_name)

        provider = providers[provider_name]

        raise ProviderNotFoundError, provider_name unless provider

        yield(provider)
      end

      def load_provider(path)
        name = Pathname(path).basename(RB_EXT).to_s.to_sym

        load_provider_file(path) unless providers.key?(name)

        self
      end

      def require_provider_file(name)
        provider_file = find_provider_file(name)

        load_provider_file(provider_file) if provider_file
      end

      # Evaluates a provider file, at most once for this registrar.
      #
      # Uses `load` rather than `require`, matching the {ManifestRegistrar}, so that a provider
      # file is evaluated once per registrar rather than once per process. Providers register
      # themselves against a particular container, so a file already `require`d for one container
      # would otherwise be skipped for the next, leaving that container without the provider.
      # Evaluating the file again also means a container built afresh picks up any changes to it.
      #
      # Files are tracked because `load`, unlike `require`, will happily evaluate one twice. A
      # provider file registering a provider under some other name is never satisfied by its own
      # loading, so it would otherwise be evaluated on every lookup of the name matching its
      # filename, and raise {ProviderAlreadyRegisteredError} the second time around.
      def load_provider_file(path)
        path = path.to_s

        return if @loaded.include?(path)

        @loaded << path

        Kernel.load path
      end

      def find_provider_file(name)
        provider_files.detect { |file| File.basename(file, RB_EXT) == name.to_s }
      end
    end
  end
end
