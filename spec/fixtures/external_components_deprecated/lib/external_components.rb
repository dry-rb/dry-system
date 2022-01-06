# frozen_string_literal: true

require "dry/system"

Dry::System.register_provider(
  :external_components,
  path: Pathname(__dir__).join("../components").realpath
)
