# frozen_string_literal: true

require_relative "system/source_provider_registry"

module Dry
  module System
    # FIXME: update docs

    # Register external component provider
    #
    # @api public
    def self.register_source_providers(path)
      source_providers.load_sources(path)
    end

    # Register an external component that can be booted within other systems
    #
    # @api public
    def self.register_source_provider(name, group:, &block)
      source_providers.register(name: name, group: group, &block)
    end

    # @api private
    def self.source_providers
      @source_providers ||= SourceProviderRegistry.new
    end
  end
end
