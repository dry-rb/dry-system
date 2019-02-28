require 'dry/system/mixin'

module Dry
  module SystemComponents
    extend Dry::System::Mixin

    config.identifier = :system
    config.boot_path = Pathname(__dir__).join('components').realpath
  end
end
