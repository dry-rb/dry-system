require 'concurrent/map'

require 'dry-equalizer'
require 'dry/system/loader'
require 'dry/system/errors'

module Dry
  module System
    class Component
      include Dry::Equalizer(:identifier, :path)

      PATH_SEPARATOR = '/'.freeze
      DEFAULT_SEPARATOR = '.'.freeze
      WORD_REGEX = /\w+/.freeze

      DEFAULT_OPTIONS = { separator: DEFAULT_SEPARATOR, namespace: nil }.freeze

      attr_reader :identifier, :path, :file, :options, :loader

      def self.new(*args)
        cache.fetch_or_store(args.hash) do
          name, options = args
          options = DEFAULT_OPTIONS.merge(options || {})

          ns, sep = options.values_at(:namespace, :separator)

          ns_name = ensure_valid_namespace(ns, sep)
          identifier = ensure_valid_identifier(name, ns_name, sep)

          path = name.to_s.gsub(sep, PATH_SEPARATOR)
          loader = options.fetch(:loader, Loader).new(path)

          super(identifier, path, options.merge(loader: loader))
        end
      end

      def self.ensure_valid_namespace(ns, sep)
        ns_name = ns.to_s
        raise InvalidNamespaceError, ns_name if ns && ns_name.include?(sep)
        ns_name
      end

      def self.ensure_valid_identifier(name, ns_name, sep)
        keys = name.to_s.scan(WORD_REGEX)

        if keys.uniq.size != keys.size
          raise InvalidComponentError, name, 'duplicated keys in the name'
        end

        keys.reject { |s| ns_name == s }.join(sep)
      end

      def self.cache
        @cache ||= Concurrent::Map.new
      end

      def initialize(identifier, path, options)
        @identifier, @path = identifier, path
        @options = options
        @file = "#{path}.rb".freeze
        @loader = options.fetch(:loader)
        freeze
      end

      def bootable?(path)
        boot_file(path).exist?
      end

      def boot_file(path)
        path.join("#{root_key}.rb")
      end

      def file_exists?(paths)
        paths.any? { |path| path.join(file).exist? }
      end

      def prepend(name)
        self.class.new(
          [name, identifier].join(separator), options.merge(loader: loader.class)
        )
      end

      def namespaced(namespace)
        self.class.new(
          path, options.merge(loader: loader.class, namespace: namespace)
        )
      end

      def separator
        options[:separator]
      end

      def namespace
        options[:namespace]
      end

      def root_key
        namespaces.first
      end

      def instance(*args)
        loader.call(*args)
      end

      private

      def namespaces
        identifier.split(separator).map(&:to_sym)
      end
    end
  end
end
