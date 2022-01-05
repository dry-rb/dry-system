# frozen_string_literal: true

require "dry/system/provider_source_registry"

module Dry
  module System
    # FIXME: update docs

    # Register external component provider
    #
    # @api public
    def self.register_provider_sources(path)
      provider_sources.load_sources(path)
    end

    # Register an external component that can be booted within other systems
    #
    # @api public
    def self.register_provider_source(name, group:, &block)
      provider_sources.register_source(name, group: group, &block)
    end

    # @api private
    def self.provider_sources
      @provider_sources ||= ProviderSourceRegistry.new
    end
  end
end
