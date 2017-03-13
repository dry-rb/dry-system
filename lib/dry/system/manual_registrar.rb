require 'pathname'
require 'dry/system/constants'

module Dry
  module System
    # Default manual registration implementation
    #
    # This is currently configured by default for every System::Container.
    # Manual registrar objects are responsible for loading files from configured
    # manual registration paths, which should hold code to explicitly register
    # certain objects with the container.
    #
    # @api private
    class ManualRegistrar
      attr_reader :container

      attr_reader :config

      def initialize(container)
        @container = container
        @config = container.config
      end

      # @api private
      def finalize!
        Dir[registrations_dir.join(RB_GLOB)].each do |file|
          call(File.basename(file, RB_EXT))
        end
      end

      # @api private
      def call(name)
        name = name.respond_to?(:root_key) ? name.root_key.to_s : name

        require(root.join(config.registrations_dir, name))
      end

      def file_exists?(name)
        name = name.respond_to?(:root_key) ? name.root_key.to_s : name

        File.exist?(File.join(registrations_dir, "#{name}#{RB_EXT}"))
      end

      private

      # @api private
      def registrations_dir
        root.join(config.registrations_dir)
      end

      # @api private
      def root
        Pathname(container.root)
      end
    end
  end
end
