# frozen_string_literal: true

# require "dry/system/auto_registrar_zeitwerk"
require "dry/system/container"
require "dry/system/loader_zeitwerk"

class App < Dry::System::Container
  # Setup zeitwerk
  require "zeitwerk"
  loader = Zeitwerk::Loader.new
  loader.push_dir Pathname(__dir__).join("../lib").realpath
  loader.setup

  # Configure dry-system
  config.loader = Dry::System::LoaderZeitwerk
  config.auto_register = %w[lib]
end
