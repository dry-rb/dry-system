# frozen_string_literal: true

require "dry/system/constants"
require "dry/system/plugins/zeitwerk/compat_inflector"

module Dry
  module System
    module Plugins
      # @api private
      class Zeitwerk < Module
        # @api private
        def self.dependencies
          ["dry/system/loader/autoloading", {"zeitwerk" => "zeitwerk"}]
        end

        # @api private
        attr_reader :options

        # @api private
        def initialize(options)
          @options = options
          super()
        end

        # @api private
        def extended(system)
          system.setting :autoloader, reader: true
          system.config.component_dirs.loader = Dry::System::Loader::Autoloading
          system.config.component_dirs.add_to_load_path = false

          system.after(:configure, &method(:setup_autoloader))

          super
        end

        private

        # @api private
        def setup_autoloader(system)
          if !system.autoloader
            system.config.autoloader = build_zeitwerk_loader(system)
          end

          push_component_dirs_to_loader(system, system.autoloader)

          system.autoloader.setup
          system.after(:finalize) { system.autoloader.eager_load } if eager_load?(system)

          system
        end

        # Build a zeitwerk loader with the configured component directories
        #
        # @return [Zeitwerk::Loader]
        #
        # @api private
        def build_zeitwerk_loader(system)
          options.fetch(:loader) { ::Zeitwerk::Loader.new }.tap do |loader|
            loader.tag = system.config.name || system.name
            loader.inflector = CompatInflector.new(system.config)
            loader.logger = method(:puts) if options[:debug]
          end
        end

        # Add component dirs to the zeitwerk loader
        #
        # @return [Zeitwerk::Loader]
        #
        # @api private
        def push_component_dirs_to_loader(system, loader)
          system.config.component_dirs.each do |dir|
            dir.namespaces.each do |ns|
              loader.push_dir(
                system.root.join(dir.path, ns.path.to_s),
                namespace: module_for_namespace(ns, system.config.inflector)
              )
            end
          end

          loader
        end

        # @api private
        def module_for_namespace(namespace, inflector)
          return Object unless namespace.const

          begin
            inflector.constantize(inflector.camelize(namespace.const))
          rescue NameError
            namespace.const.split(PATH_SEPARATOR).reduce(Object) { |parent_mod, mod_path|
              parent_mod.const_set(inflector.camelize(mod_path), Module.new)
            }
          end
        end

        # @api private
        def eager_load?(system)
          options.fetch(:eager_load) {
            system.config.respond_to?(:env) && system.config.env == :production
          }
        end
      end
    end
  end
end
