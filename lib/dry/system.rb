require 'dry/system/provider'
require 'dry/system/provider_registry'

module Dry
  module System
    # Register external component provider
    #
    # @api public
    def self.register_provider(identifier, options)
      providers.register(identifier, options)
      providers[identifier].load_components
      self
    end

    # Register an external component that can be booted within other systems
    #
    # @api public
    def self.register_component(identifier, provider:, &block)
      providers[provider].register_component(identifier, block)
      self
    end

    # @api private
    def self.providers
      @__providers__ ||= ProviderRegistry.new
    end
  end
end
