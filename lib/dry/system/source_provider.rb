# frozen_string_literal: true

require_relative "provider"

module Dry
  module System
    class SourceProvider
      attr_reader :name, :source_block

      def initialize(name:, source_block:)
        @name = name
        @source_block = source_block
      end

      def to_provider(**options)
        Provider.new(name: name, source_block: source_block, **options)
      end
    end
  end
end
