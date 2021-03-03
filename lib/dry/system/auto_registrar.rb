# frozen_string_literal: true

require "dry/system/constants"
require_relative "component"

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

      def initialize(container)
        @container = container
      end

      # @api private
      def finalize!
        container.component_dirs.each do |component_dir|
          call(component_dir) if component_dir.auto_register?
        end
      end

      # @api private
      def call(component_dir)
        components(component_dir).each do |component|
          next unless register_component?(component)

          container.register(component.identifier, memoize: component.memoize?) { component.instance }
        end
      end

      private

      def components(component_dir)
        files(component_dir.full_path).map { |file_path|
          component_dir.component_for_path(file_path)
        }
      end

      def files(dir)
        raise ComponentDirNotFoundError, dir unless Dir.exist?(dir)

        Dir["#{dir}/**/#{RB_GLOB}"].sort
      end

      def register_component?(component)
        !container.registered?(component) && component.auto_register?
      end
    end
  end
end
