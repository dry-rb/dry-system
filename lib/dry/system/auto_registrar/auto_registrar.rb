require 'dry/system/constants'
require 'dry/system/auto_registrar/magic_comments_parser'
require 'dry/system/auto_registrar/configuration'

module Dry
  module System
    module AutoRegistrar
      # Default auto-registration implementation
      #
      # This is currently configured by default for every System::Container.
      # Auto-registrar objects are responsible for loading files from configured
      # auto-register paths and registering components automatically within the
      # container.
      #
      # @api private
      class AutoRegistrar
        attr_reader :container, :root, :loader, :default_namespace

        def initialize(container, root, loader:, default_namespace: nil)
          @container = container
          @root = root
          @loader = loader
          @default_namespace = default_namespace
        end

        # @api private
        def finalize!(paths)
          paths.each { |dir| call(dir) }
        end

        # @api private
        def call(dir)
          registration_config = Configuration.new

          yield(registration_config) if block_given?

          memoize = registration_config.memoize

          identifieds(dir).each do |identified|
            next if !identified.auto_register? || registration_config.exclude[identified]

            auto_register(identified, memoize: memoize) do |loader|
              registration_config.instance[identified, loader]
            end
          end
        end

        def auto_register(identified, memoize: false, &block)
          return if container.key?(identified.identifier)

          loader.new(identified.path) do |loader|
            container.register(identified.identifier, memoize: memoize) do
              if block_given?
                block.call(loader)
              else
                loader.instance
              end
            end
          end
        end

        private

        # @api private
        def identifieds(dir)
          files(dir).map do |file_name|
            identifier = identifier_for(dir, file_name).map(&:to_sym)

            Identifier.new(identifier, namespace: default_namespace, **file_options(file_name))
          end
        end

        # @api private
        def files(dir)
          Dir["#{root}/#{dir}/**/#{RB_GLOB}"]
        end

        def identifier_for(dir, file_path)
          dir_root = root.join(dir.to_s.split('/')[0])
          file_path.to_s.sub("#{dir_root}/", '').sub(RB_EXT, EMPTY_STRING).split(PATH_SEPARATOR)
        end

        # @api private
        def file_options(file_name)
          MagicCommentsParser.(file_name)
        end
      end
    end
  end
end
