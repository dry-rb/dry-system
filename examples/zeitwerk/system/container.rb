# frozen_string_literal: true

require "dry/system/auto_registrar_zeitwerk"
require "dry/system/container"
require "dry/system/loader_zeitwerk"

class App < Dry::System::Container
  require "zeitwerk"

  loader = Zeitwerk::Loader.new
  loader.push_dir Pathname(__dir__).join("../lib").realpath
  loader.setup

  # config.auto_registrar = Dry::System::AutoRegistrarZeitwerk
  config.loader = Dry::System::LoaderZeitwerk
  config.auto_register = %w[lib]

  # Is this needed? No, it's not (though might it be helpful to keep it in place?)
  #
  # FIXME: it's needed for lazy resolution, which shouldn't strictly be necessary if we're
  # using zeitwerk
  load_paths! "lib"
end
