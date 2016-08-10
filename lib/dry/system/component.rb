require 'dry-equalizer'
require 'dry/system/loader'

module Dry
  module System
    class Component
      include Dry::Equalizer(:identifier, :path)

      PATH_SEPARATOR = '/'.freeze
      WORD_REGEX = /\w+/.freeze

      attr_reader :identifier, :path, :file, :options, :loader

      def self.new(name, options)
        ns, sep = options.values_at(:namespace, :separator).map(&:to_s)

        identifier = name.to_s.scan(WORD_REGEX).reject { |s| ns == s }.join(sep)
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

      def dependency?(name)
        *deps, _ = namespaces
        (deps & name.split(separator).map(&:to_sym)).size > 0
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
