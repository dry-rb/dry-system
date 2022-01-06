# frozen_string_literal: true

require "dry/core/deprecations"
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

    def self.register_provider(_name, options)
      Dry::Core::Deprecations.announce(
        "Dry::System.register_provider",
        "Use `Dry::System.register_source_providers` instead",
        tag: "dry-system",
        uplevel: 1
      )

      register_source_providers(options.fetch(:path))
    end

    #
    # @api public
    def self.register_source_provider(name, group:, &block)
      source_providers.register(name: name, group: group, &block)
    end

    def self.register_component(name, provider:, &block)
      Dry::Core::Deprecations.announce(
        "Dry::System.register_component",
        "Use `Dry::System.register_source_provider` instead",
        tag: "dry-system",
        uplevel: 1
      )

      register_source_provider(name, group: provider, &block)
    end

    # @api private
    def self.source_providers
      @source_providers ||= SourceProviderRegistry.new
    end
  end
end
