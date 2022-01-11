# frozen_string_literal: true

require "dry/core/deprecations"
require_relative "constants"
require_relative "provider/source"

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

      def register_from_block(name:, group:, target_container:, &block)
        register(
          name: name,
          group: group,
          source: Provider::Source.for(
            name: name,
            group: group,
            target_container: target_container,
            &block
          )
        )
      end

      def resolve(name:, group:)
        if group == :system
          Dry::Core::Deprecations.announce(
            "Providers using `from: :system`",
            "Use `from: :dry_system` instead",
            tag: "dry-system",
            uplevel: 1
          )

          group = :dry_system
        end

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
