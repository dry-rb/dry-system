# frozen_string_literal: true

require_relative "provider"

module Dry
  module System
    class SourceProvider
      attr_reader :name, :lifecycle_block

      def initialize(name:, lifecycle_block:)
        @name = name
        @lifecycle_block = lifecycle_block
      end

      def to_provider(**options)
        Provider.new(name: name, lifecycle_block: lifecycle_block, **options)
      end
    end
  end
end
