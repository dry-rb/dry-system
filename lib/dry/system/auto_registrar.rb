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

          container.register(component.key, memoize: component.memoize?) { component.instance }
        end
      end

      private

      def components(component_dir)
        files(component_dir).map { |file_path|
          # p file_path
          component_dir.component_for_path(file_path)
        }
      end

      def files(component_dir)
        dir_path = component_dir.full_path

        raise ComponentDirNotFoundError, dir_path unless Dir.exist?(dir_path)

        (component_dir.namespaces.map { |(path_namespace, _)|
          if path_namespace.nil?
            []
          else
            Dir["#{dir_path}/#{path_namespace}/**/#{RB_GLOB}"]
          end
        }.flatten + Dir["#{dir_path}/**/#{RB_GLOB}"]).uniq.tap do |ff|
            # byebug
          end

        # Dir["#{component_dir.full_path}/**/#{RB_GLOB}"].sort
      end

      def register_component?(component)
        !container.registered?(component.key) && component.auto_register?
      end
    end
  end
end
