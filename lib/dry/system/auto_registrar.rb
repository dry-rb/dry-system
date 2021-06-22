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

          puts "auto_registering #{component.key}"

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

        # FIXME: this is broken - we actually want to get all the files first, then sort
        # by namespaces, which would allow the `nil` namespace to go first, if provided
        # that way

        # Old way (not right):
        # (component_dir.namespaces.map { |(path_namespace, _)|
        #   if path_namespace.nil?
        #     []
        #   else
        #     Dir["#{dir_path}/#{path_namespace}/**/#{RB_GLOB}"]
        #   end
        # }.flatten + Dir["#{dir_path}/**/#{RB_GLOB}"]).uniq.tap do |ff|
        #   # byebug
        # end

        # Original way (won't work anymore):
        # Dir["#{component_dir.full_path}/**/#{RB_GLOB}"].sort

        ## Maybe correct? (but also hugely inefficient):

        ns_sort_map = component_dir.namespaces.map.with_index { |(path_namespace, _), i|
          [
            path_namespace&.gsub(".", "/"), # FIXME make right
            i,
          ]
        }.to_h

        p ns_sort_map

        Dir["#{component_dir.full_path}/**/#{RB_GLOB}"].sort_by { |file_path|
          # ns_sort_map

          sort = nil

          relative_file_path = Pathname(file_path).relative_path_from(component_dir.full_path).to_s

          ns_sort_map.each do |prefix, sort_i|
            # byebug unless prefix.nil?
            next if prefix.nil?

            if relative_file_path.start_with?(prefix)
              sort = sort_i
              break
            end
          end

          if sort.nil?
            sort = ns_sort_map.fetch(nil, 0)
          end

          puts "#{file_path}: #{sort}"
          sort
        }.tap do |ff|
          # byebug
        end
      end

      def register_component?(component)
        !container.registered?(component.key) && component.auto_register?
      end
    end
  end
end
