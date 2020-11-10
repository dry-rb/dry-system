# frozen_string_literal: true

require "concurrent/map"

require "dry-equalizer"
require "dry/inflector"
require "dry/system/loader"
require "dry/system/errors"
require "dry/system/constants"

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

      DEFAULT_OPTIONS = {
        separator: DEFAULT_SEPARATOR,
        namespace: nil,
        inflector: Dry::Inflector.new
      }.freeze

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
      def self.new(*args, &block)
        cache.fetch_or_store([*args, block].hash) do
          name, options = args
          options = DEFAULT_OPTIONS.merge(options || EMPTY_HASH)

          ns, sep, inflector = options.values_at(:namespace, :separator, :inflector)
          identifier = extract_identifier(name, ns, sep)

          path = name.to_s.gsub(sep, PATH_SEPARATOR)
          loader = options.fetch(:loader, Loader).new(path, inflector)

          super(identifier, path, options.merge(loader: loader))
        end
      end

      # @api private
      def self.extract_identifier(name, ns, sep)
        name_s = name.to_s
        identifier = ns ? remove_namespace_from_name(name_s, ns) : name_s

        identifier.scan(WORD_REGEX).join(sep)
      end

      # @api private
      def self.remove_namespace_from_name(name, ns)
        match_value = name.match(/^(?<remove_namespace>#{ns})(?<separator>\W)(?<identifier>.*)/)

        match_value ? match_value[:identifier] : name
      end

      # @api private
      def self.cache
        @cache ||= Concurrent::Map.new
      end

      # @api private
      def initialize(identifier, path, options)
        @identifier = identifier
        @path = path
        @options = options
        @file = "#{path}#{RB_EXT}"
        @loader = options.fetch(:loader)
        freeze
      end

      def require!
        loader.require!
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
      ruby2_keywords(:instance) if respond_to?(:ruby2_keywords, true)

      # @api private
      def bootable?
        false
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
