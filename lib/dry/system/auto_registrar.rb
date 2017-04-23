require 'dry/system/constants'

module Dry
  module System
    # Default auto-registration implementation
    #
    # This is currently configured by default for every System::Container.
    # Auto-registrar objects are responsible for loading files from configured
    # auto-register paths and registering components automatically within the
    # container.
    #
    # @api private
    class AutoRegistrar
      attr_reader :container

      attr_reader :config

      def initialize(container)
        @container = container
        @config = container.config
      end

      # @api private
      def finalize!
        Array(config.auto_register).each { |dir| call(dir) }
      end

      # @api private
      def call(dir, &block)
        components(dir).each do |component|
          next if !component.auto_register?

          container.require_component(component) do
            if block
              register(component.identifier, yield(component))
            else
              register(component.identifier) { component.instance }
            end
          end
        end
      end

      private

      # @api private
      def components(dir)
        files(dir).
          map { |file_path| [file_path, file_options(file_path)] }.
          map { |(file_path, options)| component(relative_path(dir, file_path), **options) }.
          reject { |component| key?(component.identifier) }
      end

      # @api private
      def files(dir)
        Dir["#{root}/#{dir}/**/*.rb"]
      end

      def relative_path(dir, file_path)
        dir_root = root.join(dir.to_s.split('/')[0])
        file_path.to_s.sub("#{dir_root}/", '').sub(RB_EXT, EMPTY_STRING)
      end

      VALID_LINE_RE = /^(#.*)?$/
      MAGIC_COMMENT_RE = /^#\s+(?<name>[A-Za-z_]+):\s+(?<value>.+?)$/

      def file_options(file_path)
        {}.tap do |options|
          File.foreach(file_path) do |line|
            break if !line.match?(VALID_LINE_RE)

            if (match = line.match(MAGIC_COMMENT_RE))
              options[match[:name].to_sym] = match[:value]
            end
          end
        end
      end

      # @api private
      def component(path, options)
        container.component(path, options)
      end

      # @api private
      def root
        container.root
      end

      # @api private
      def key?(name)
        container.key?(name)
      end

      # @api private
      def register(*args, &block)
        container.register(*args, &block)
      end
    end
  end
end
