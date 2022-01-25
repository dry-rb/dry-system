# frozen_string_literal: true

require "dry/system/plugins/zeitwerk/compat_inflector"

module Dry
  module System
    module Plugins
      # @api private
      class Zeitwerk < Module
        attr_reader :options

        # @api private
        def initialize(options)
          @options = options
          super()
        end

        # @api private
        def extended(system)
          require "dry/system/loader/autoloading"

          system.setting :autoloader, reader: true
          system.config.component_dirs.loader = Dry::System::Loader::Autoloading
          system.config.component_dirs.add_to_load_path = false

          system.after(:configure, &method(:setup_autoloader))

          super
        end

        private

        # @api private
        def setup_autoloader(system)
          return system if system.registered?(:autoloader)

          if system.config.autoloader
            system.register(:autoloader, system.config.autoloader)
          else
            system.config.autoloader = build_zeitwerk_loader(system)
          end

          system
        end

        # Build a zeitwerk loader with the configured component directories
        #
        # @return [Zeitwerk::Loader]
        #
        # @api private
        def build_zeitwerk_loader(system)
          require "zeitwerk"

          loader = options.fetch(:loader) { ::Zeitwerk::Loader.new }
          loader.tag = system.config.name || system.name
          loader.logger = method(:puts) if options[:debug]
          loader.inflector = CompatInflector.new(system.config)
          push_component_dirs_to_loader(system, loader)
          loader.setup
          system.after(:finalize) { loader.eager_load } if eager_load?(system)
          loader
        end

        # Add component dirs to the zeitwerk loader
        #
        # @return [Zeitwerk::Loader]
        #
        # @api private
        def push_component_dirs_to_loader(system, loader)
          system.config.component_dirs.each do |dir|
            raise ZeitwerkAddToLoadPathError, dir if dir.add_to_load_path

            loader.push_dir(system.config.root.join(dir.path))
          end

          loader
        end

        # @api private
        def eager_load?(system)
          options.fetch(:eager_load) do
            system.config.respond_to?(:env) && system.config.env == :production
          end
        end
      end
    end
  end
end
