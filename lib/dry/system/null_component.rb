# frozen_string_literal: true

require "dry/core/equalizer"

module Dry
  module System
    # @api private
    class NullComponent
      include Dry::Equalizer(:identifier)

      attr_reader :identifier

      def initialize(identifier)
        @identifier = identifier
      end

      def loadable?
        false
      end

      def key
        identifier.to_s
      end

      def root_key
        identifier.root_key
      end
    end
  end
end
