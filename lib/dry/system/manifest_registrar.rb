# frozen_string_literal: true

require "dry/system/constants"

module Dry
  module System
    # Default manifest registration implementation
    #
    # This is configured by default for every System::Container. The manifest registrar is
    # responsible for loading manifest files that contain code to manually register
    # certain objects with the container.
    #
    # @api private
    class ManifestRegistrar
      # @api private
      attr_reader :container

      # @api private
      attr_reader :config

      # @api private
      def initialize(container)
        @container = container
        @config = container.config
      end

      # @api private
      def finalize!
        eager_loaded = container.keys.each_with_object(Set.new) do |key, set|
          set << Identifier.new(key).root_key
        end

        ::Dir[registrations_dir.join(RB_GLOB)].each do |file|
          ident = Identifier.new(File.basename(file, RB_EXT))
          call(ident) unless eager_loaded.include?(ident.root_key)
        end
      end

      # @api private
      def call(component)
        load(root.join(config.registrations_dir, "#{component.root_key}#{RB_EXT}"))
      end

      # @api private
      def file_exists?(component)
        ::File.exist?(::File.join(registrations_dir, "#{component.root_key}#{RB_EXT}"))
      end

      private

      # @api private
      def registrations_dir
        root.join(config.registrations_dir)
      end

      # @api private
      def root
        container.root
      end
    end
  end
end
