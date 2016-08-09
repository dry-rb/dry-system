require 'dry-equalizer'
require 'dry/system/loader'

module Dry
  module System
    class Component
      include Dry::Equalizer(:identifier, :path)

      PATH_SEPARATOR = '/'.freeze

      attr_reader :identifier, :path, :file, :options, :loader

      def self.new(name, options)
        ns, sep = options.values_at(:namespace, :separator)

        identifier =
          if ns
            name.to_s.sub(%r[^#{ns}#{sep}], '')
          else
            name.to_s.gsub(PATH_SEPARATOR, sep)
          end

        path = name.to_s.gsub(sep, PATH_SEPARATOR)
        loader = options.fetch(:loader, Loader).new(path)

        super(identifier, path, options.merge(loader: loader))
      end

      def initialize(identifier, path, options)
        @identifier, @path = identifier, path
        @options = options
        @file = "#{path}.rb".freeze
        @loader = options.fetch(:loader)
        freeze
      end

      def separator
        options[:separator]
      end

      def namespace
        options[:namespace]
      end

      def dependency?(name)
        *deps, _ = namespaces
        (deps & name.split(separator).map(&:to_sym)).size > 0
      end

      def root_key
        namespaces.first
      end

      def namespaces
        identifier.split(separator).map(&:to_sym)
      end

      def instance(*args)
        loader.call(*args)
      end
    end
  end
end
