require 'dry/system'

Dry::System.register_provider(
  :system_components,
  boot_path: Pathname(__dir__).join('system_components').realpath
)
