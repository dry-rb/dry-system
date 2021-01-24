# frozen_string_literal: true

require "concurrent/map"

require "dry-equalizer"
require "dry/inflector"
require "dry/system/loader"
require "dry/system/errors"
require "dry/system/constants"
require "dry/system/magic_comments_parser"

module Dry
  module System
    # Components are objects providing information about auto-registered files.
    # They expose an API to query this information and use a configurable
    # loader object to initialize class instances.
    #
    # @api public
    class Component
      include Dry::Equalizer(:identifier, :path, :file_path, :options)

      DEFAULT_OPTIONS = {
        separator: DEFAULT_SEPARATOR,
        inflector: Dry::Inflector.new,
        loader: Loader
      }.freeze

      # @!attribute [r] identifier
      #   @return [String] component's unique identifier
      attr_reader :identifier

      # @!attribute [r] path
      #   @return [String] component's relative path
      attr_reader :path

      # @!attribute [r] file_path
      #   @return [String, nil] full path to the component's file, if found
      attr_reader :file_path

      # @!attribute [r] options
      #   @return [Hash] component's options
      attr_reader :options

      # @!attribute [r] loader
      #   @return [Object#call] component's loader object
      attr_reader :loader

      # Returns a component with a namespace and path provided from a file found within
      # the given component dirs. If no file is found, a component is returned without
      # these attributes.
      #
      # @return [Dry::System::Component]
      # @api private
      def self.locate(identifier, component_dirs, options = EMPTY_HASH)
        options = DEFAULT_OPTIONS.merge(options)

        path = identifier.to_s.gsub(options[:separator], PATH_SEPARATOR)

        found_dir, found_path = component_dirs.detect { |dir|
          if (component_file = dir.component_file(path))
            break [dir, component_file]
          end
        }

        return new(identifier, options) unless found_path

        new_from_component_dir(identifier, found_dir, found_path, options)
      end

      # @api private
      def self.new_from_component_dir(identifier, component_dir, file_path, options = EMPTY_HASH)
        # Replace default options (provided via args) with more component-local values
        options = {
          **DEFAULT_OPTIONS,
          **options,
          **component_dir.component_options,
          **MagicCommentsParser.(file_path)
        }

        new(
          identifier,
          namespace: component_dir.default_namespace,
          file_path: file_path,
          **options
        )
      end

      # @api private
      def self.new(identifier, options = EMPTY_HASH)
        options = DEFAULT_OPTIONS.merge(options)

        namespace, separator = options.values_at(:namespace, :separator)

        identifier = extract_identifier(identifier, namespace, separator)

        path = identifier.gsub(separator, PATH_SEPARATOR)
        if namespace
          namespace = namespace.to_s.gsub(separator, PATH_SEPARATOR)
          path = "#{namespace}#{PATH_SEPARATOR}#{path}"
        end

        super(identifier, path: path, **options)
      end

      # @api private
      def self.extract_identifier(identifier, namespace, separator)
        identifier = identifier.to_s

        identifier = namespace ? remove_namespace_from_name(identifier, namespace) : identifier

        identifier.scan(WORD_REGEX).join(separator)
      end
      private_class_method :extract_identifier

      # @api private
      def self.remove_namespace_from_name(name, namespace)
        match_value = name.match(/^(?<remove_namespace>#{namespace})(?<separator>\W)(?<identifier>.*)/)

        match_value ? match_value[:identifier] : name
      end
      private_class_method :remove_namespace_from_name

      attr_reader :inflector

      # @api private
      def initialize(identifier, path:, file_path: nil, **options)
        @identifier = identifier
        @path = path
        @file_path = file_path
        @options = options
        @inflector = options.fetch(:inflector)
        @loader = options.fetch(:loader).new(self)
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
      ruby2_keywords(:instance) if respond_to?(:ruby2_keywords, true)

      # @api private
      def bootable?
        false
      end

      # Returns true if the component has a corresponding file
      #
      # @return [Boolean]
      # @api private
      def file_exists?
        !!file_path
      end

      # @api private
      def namespaced(namespace)
        self.class.new(
          identifier,
          path: path,
          file_path: nil,
          **options,
          loader: loader.class,
          namespace: namespace,
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
        callable_option?(options[:auto_register])
      end

      # @api private
      def memoize?
        callable_option?(options[:memoize])
      end

      # @api private
      def root_key
        identifier.split(separator).map(&:to_sym).first
      end

      private

      def callable_option?(value)
        if value.respond_to?(:call)
          !!value.call(self)
        else
          !!value
        end
      end
    end
  end
end
