# frozen_string_literal: true

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
          provider = providers.detect { |c| c.name == name }

          provider || raise(InvalidComponentNameError, name) # TODO: fix error name
        end
      end
    end
  end
end
