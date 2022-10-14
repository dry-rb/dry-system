# frozen_string_literal: true

require "zeitwerk"
require "dry/core"
require_relative "system/provider_source_registry"

module Dry
  module System
    # @api private
    def self.loader
      @loader ||= Zeitwerk::Loader.new.tap do |loader|
        root = File.expand_path("..", __dir__)
        loader.tag = "dry-system"
        loader.inflector = Zeitwerk::GemInflector.new("#{root}/dry-system.rb")
        loader.push_dir(root)
        loader.ignore(
          "#{root}/dry-system.rb",
          "#{root}/dry/system/{constants,errors,stubs,version}.rb"
        )
        loader.inflector.inflect("dsl" => "DSL")
      end
    end

    # Registers the provider sources in the files under the given path
    #
    # @api public
    def self.register_provider_sources(path)
      provider_sources.load_sources(path)
    end

    def self.register_provider(_name, options)
      Dry::Core::Deprecations.announce(
        "Dry::System.register_provider",
        "Use `Dry::System.register_provider_sources` instead",
        tag: "dry-system",
        uplevel: 1
      )

      register_provider_sources(options.fetch(:path))
    end

    # Registers a provider source, which can be used as the basis for other providers
    #
    # @api public
    def self.register_provider_source(name, group:, source: nil, &block)
      if source && block
        raise ArgumentError, "You must supply only a `source:` option or a block, not both"
      end

      if source
        provider_sources.register(name: name, group: group, source: source)
      else
        provider_sources.register_from_block(
          name: name,
          group: group,
          target_container: self,
          &block
        )
      end
    end

    def self.register_component(name, provider:, &block)
      Dry::Core::Deprecations.announce(
        "Dry::System.register_component",
        "Use `Dry::System.register_provider_source` instead",
        tag: "dry-system",
        uplevel: 1
      )

      register_provider_source(name, group: provider, &block)
    end

    # @api private
    def self.provider_sources
      @provider_sources ||= ProviderSourceRegistry.new
    end

    loader.setup
  end
end
