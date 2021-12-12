# frozen_string_literal: true

module Dry
  module System
    module Plugins
      module Zeitwerk
        class CompatInflector
          attr_reader :config

          def initialize(config)
            @config = config
          end

          def camelize(string, _)
            config.inflector.camelize(string)
          end
        end

        # @api private
        def self.extended(system)
          system.before(:configure, &:configure_autoloading)
          system.after(:configure, &:setup_autoloader)

          super
        end

        # Configure autoloading on the container
        #
        # @return [self]
        #
        # @api private
        def configure_autoloading
          require "dry/system/loader/autoloading"

          setting :autoloader, reader: true

          config.component_dirs.loader = Dry::System::Loader::Autoloading
          config.component_dirs.add_to_load_path = false
          self
        end

        # Set a logger
        #
        # This is invoked automatically when a container is being configured
        #
        # @return [self]
        #
        # @api private
        def setup_autoloader
          return self if registered?(:autoloader)

          if config.autoloader
            register(:autoloader, config.logger)
          else
            config.autoloader = build_zeitwerk_loader
            register(:autoloader, config.autoloader)
            self
          end
        end

        # Build a zeitwerk loader with the configured component directories
        #
        # @return [Zeitwerk::Loader]
        #
        # @api private
        def build_zeitwerk_loader
          require "zeitwerk"

          loader = ::Zeitwerk::Loader.new
          loader.inflector = CompatInflector.new(config)
          config.component_dirs.each do |dir|
            raise ZeitwerkAddToLoadPathError, dir if dir.add_to_load_path

            loader.push_dir(config.root.join(dir.path))
          end
          loader.setup
          loader
        end
      end
    end
  end
end
