# frozen_string_literal: true

require "dry/system/provider"
require "dry/system/provider_registry"

module Dry
  module System
    # Register external component provider
    #
    # @api public
    def self.register_provider(name, options)
      providers.register(name, options)
      providers[name].load_components
      self
    end

    # Register an external component that can be booted within other systems
    #
    # @api public
    def self.register_component(name, provider:, &block)
      providers[provider].register_component(name, block)
      self
    end

    # @api private
    def self.providers
      @providers ||= ProviderRegistry.new
    end
  end
end
