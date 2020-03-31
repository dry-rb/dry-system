# frozen_string_literal: true

require 'dry/system'

Dry::System.register_provider(
  :system,
  boot_path: Pathname(__dir__).join('system_components').realpath
)
