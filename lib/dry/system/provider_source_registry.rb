# frozen_string_literal: true

require_relative "constants"
require_relative "components/bootable"

module Dry
  module System
    class ProviderSourceRegistry
      attr_reader :sources

      def initialize
        @sources = {}
      end

      def load_sources(path)
        Dir[File.join(path, "**/#{RB_GLOB}")].sort.each do |file|
          require file
        end
      end

      def register_source(name, group:, &block)
        sources[key(name, group)] = Components::Bootable.new(name, &block)
      end

      # FIXME: better method name
      def provider_source(component_name, group, options = {})
        # for now, nabbed this from the old Provider#component
        component_key = options[:key] || component_name
        sources[key(component_key, group)].new(component_name, options)
      end

      private

      def key(name, group)
        {name: name, group: group}
      end
    end
  end
end
