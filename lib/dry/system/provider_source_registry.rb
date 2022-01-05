# frozen_string_literal: true

require_relative "constants"
require_relative "source_provider"

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
        sources[key(name, group)] = SourceProvider.new(name: name, lifecycle_block: block)
      end

      # FIXME: better method name
      def provider_source(name, group, key: nil, **options)
        # Nabbed this from the old Provider#component
        # TODO: rename "key" to something else
        component_key = key || name
        sources[key(component_key, group)].to_provider(name: name, **options)
      end

      private

      def key(name, group)
        {name: name, group: group}
      end
    end
  end
end
