require 'inflecto'
require 'dry-equalizer'

module Dry
  module System
    class Component
      include Dry::Equalizer(:identifier, :path)

      attr_reader :identifier, :path, :file, :options

      def self.new(name, options)
        ns, ns_sep, path_sep = options.values_at(
          :default_namespace, :namespace_separator, :path_separator
        )

        identifier =
          if ns
            name.to_s.sub(%r[^#{ns}#{ns_sep}], '')
          else
            name.to_s.gsub(path_sep, ns_sep)
          end

        path = name.to_s.gsub(ns_sep, path_sep)

        super(identifier, path, options)
      end

      def initialize(identifier, path, options)
        @identifier, @path = identifier, path
        @options = options
        @file = "#{path}.rb".freeze
        freeze
      end

      def separator
        options[:namespace_separator]
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
        if constant.respond_to?(:instance) && !constant.respond_to?(:new)
          constant.instance(*args) # a singleton
        else
          constant.new(*args)
        end
      end

      def constant
        Inflecto.constantize(constant_name)
      end

      private

      def constant_name
        Inflecto.camelize(path)
      end
    end
  end
end
