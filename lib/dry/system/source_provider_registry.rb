# frozen_string_literal: true

require_relative "constants"
require_relative "provider"

module Dry
  module System
    # @api private
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

      def register(name:, group:, source:)
        providers[key(name, group)] = source
      end

      def register_from_block(name:, group:, &block)
        register(
          name: name,
          group: group,
          source: Provider.source_class(name: name, group: group, &block)
        )
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
