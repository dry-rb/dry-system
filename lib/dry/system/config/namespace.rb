# frozen_string_literal: true

require "dry/core/equalizer"

module Dry
  module System
    module Config
      class Namespace
        ROOT_PATH = nil

        include Dry::Equalizer(:path, :identifier_namespace, :const_namespace)

        attr_reader :path

        attr_reader :identifier_namespace

        attr_reader :const_namespace

        def self.default_root
          self.new(
            path: ROOT_PATH,
            identifier_namespace: nil,
            const_namespace: nil,
          )
        end

        def initialize(path:, identifier_namespace:, const_namespace:)
          @path = path
          @identifier_namespace = identifier_namespace
          @const_namespace = const_namespace
        end

        def root?
          path == ROOT_PATH
        end
      end
    end
  end
end
