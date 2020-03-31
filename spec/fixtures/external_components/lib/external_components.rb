# frozen_string_literal: true

require "dry/system"

Dry::System.register_provider(
  :external_components,
  boot_path: Pathname(__dir__).join("../components").realpath
)

Dry::System.register_provider(
  :alt,
  boot_path: Pathname(__dir__).join("../alt-components").realpath
)
