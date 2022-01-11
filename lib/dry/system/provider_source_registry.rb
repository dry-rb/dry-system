# frozen_string_literal: true

require_relative "constants"
require_relative "provider"

module Dry
  module System
    # @api private
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

      def register(name:, group:, source:)
        sources[key(name, group)] = source
      end

      def register_from_block(name:, group:, &block)
        register(
          name: name,
          group: group,
          source: Provider.source_class(name: name, group: group, &block)
        )
      end

      def resolve(name:, group:)
        sources[key(name, group)].tap { |source|
          unless source
            raise ProviderSourceNotFoundError.new(
              name: name,
              group: group,
              keys: sources.keys
            )
          end
        }
      end

      private

      def key(name, group)
        {group: group, name: name}
      end
    end
  end
end
