# frozen_string_literal: true

require "dry/system/errors"

module Dry
  module System
    class Booter
      class ProviderRegistry
        include Enumerable

        attr_reader :providers

        def initialize
          @providers = []
        end

        def each(&block)
          providers.each(&block)
        end

        def register(provider)
          @providers << provider
        end

        def exists?(name)
          providers.any? { |provider| provider.name == name }
        end

        def [](name)
          provider = providers.detect { |provider| provider.name == name }

          provider || raise(ProviderNotFoundError, name)
        end
      end
    end
  end
end
