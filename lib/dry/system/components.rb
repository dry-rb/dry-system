# frozen_string_literal: true

require "dry/core/deprecations"

Dry::Core::Deprecations.announce(
  "require \"dry/system/components\"",
  "Use `require \"dry/system/provider_sources\"` instead",
  tag: "dry-system",
  uplevel: 1
)

require_relative "provider_sources"
