require 'concurrent/map'

require 'dry-equalizer'
require 'dry/system/loader'
require 'dry/system/errors'
require 'dry/system/constants'

module Dry
  module System
    # Components are objects providing information about auto-registered files.
    # They expose an API to query this information and use a configurable
    # loader object to initialize class instances.
    #
    # Components are created automatically through auto-registration and can be
    # accessed through `Container.auto_register!` which yields them.
    #
    # @api public
    class Component
      include Dry::Equalizer(:identifier, :path)

      DEFAULT_OPTIONS = { separator: DEFAULT_SEPARATOR, namespace: nil }.freeze

      # @!attribute [r] identifier
      #   @return [String] component's unique identifier
      attr_reader :identifier

      # @!attribute [r] path
      #   @return [String] component's relative path
      attr_reader :path

      # @!attribute [r] file
      #   @return [String] component's file name
      attr_reader :file

      # @!attribute [r] options
      #   @return [Hash] component's options
      attr_reader :options

      # @!attribute [r] loader
      #   @return [Object#call] component's loader object
      attr_reader :loader

      # @api private
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

      # @api private
      def self.ensure_valid_namespace(ns, sep)
        ns_name = ns.to_s
        raise InvalidNamespaceError, ns_name if ns && ns_name.include?(sep)
        ns_name
      end

      # @api private
      def self.ensure_valid_identifier(name, ns_name, sep)
        keys = name.to_s.scan(WORD_REGEX)

        if keys.uniq.size != keys.size
          raise InvalidComponentError, name, 'duplicated keys in the name'
        end

        keys.reject { |s| ns_name == s }.join(sep)
      end

      # @api private
      def self.cache
        @cache ||= Concurrent::Map.new
      end

      # @api private
      def initialize(identifier, path, options)
        @identifier, @path = identifier, path
        @options = options
        @file = "#{path}.rb".freeze
        @loader = options.fetch(:loader)
        freeze
      end

      # Returns components instance
      #
      # @example
      #   class MyApp < Dry::System::Container
      #     configure do |config|
      #       config.name = :my_app
      #       config.root = Pathname('/my/app')
      #     end
      #
      #     auto_register!('lib/clients') do |component|
      #       # some custom initialization logic, ie:
      #       constant = component.loader.constant
      #       constant.create
      #     end
      #   end
      #
      # @return [Object] component's class instance
      #
      # @api public
      def instance(*args)
        loader.call(*args)
      end

      # @api private
      def bootable?(path)
        boot_file(path).exist?
      end

      # @api private
      def boot_file(path)
        path.join("#{root_key}.rb")
      end

      # @api private
      def file_exists?(paths)
        paths.any? { |path| path.join(file).exist? }
      end

      # @api private
      def prepend(name)
        self.class.new(
          [name, identifier].join(separator), options.merge(loader: loader.class)
        )
      end

      # @api private
      def namespaced(namespace)
        self.class.new(
          path, options.merge(loader: loader.class, namespace: namespace)
        )
      end

      # @api private
      def separator
        options[:separator]
      end

      # @api private
      def namespace
        options[:namespace]
      end

      # @api private
      def auto_register?
        !!options.fetch(:auto_register) { true }
      end

      # @api private
      def root_key
        namespaces.first
      end

      private

      def namespaces
        identifier.split(separator).map(&:to_sym)
      end
    end
  end
end
