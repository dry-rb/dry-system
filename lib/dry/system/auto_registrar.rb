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
        # components(component_dir).each do |component|
        component_dir.each_component do |component|
          next unless register_component?(component)

          puts "auto_registering #{component.key}"

          container.register(component.key, memoize: component.memoize?) { component.instance }
        end
      end

      private

      # def components(component_dir)
      #   component_dir.files.map { |file_path|
      #     # p file_path
      #     component_dir.component_for_path(file_path)
      #   }
      # end

      def register_component?(component)
        !container.registered?(component.key) && component.auto_register?
      end
    end
  end
end
