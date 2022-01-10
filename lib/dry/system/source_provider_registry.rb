# frozen_string_literal: true

require_relative "constants"
require_relative "source_provider"
require_relative "provider/source"
require_relative "provider/source_builder"

module Dry
  module System
    class SourceProviderRegistry
      attr_reader :providers

      def initialize
        @providers = {}
      end

      def load_sources(path)
        Dir[File.join(path, "**/#{RB_GLOB}")].sort.each do |file|
          require file
        end
      end

      def register(name:, group:, &block)
        source_class = Provider::SourceBuilder.source_from(name, group, &block)
        providers[key(name, group)] = source_class

        # @source = SourceDSL.source_from(name, &source_block)
        # .new(provider_container: container, target_container: target_container, &refinement_block)

        # providers[key(name, group)] = SourceProvider.new(name: name, source_block: block)
      end

      def resolve(name:, group:)
        providers[key(name, group)]
      end

      private

      def key(name, group)
        {group: group, name: name}
      end
    end
  end
end
