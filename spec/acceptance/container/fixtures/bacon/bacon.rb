require 'dry/system/mixin'
require 'pathname'

module Test
  module Bacon
    extend Dry::System::Mixin

    config.identifier = :bacon
    config.boot_path = Pathname.new(__dir__).join('providers')
    config.auto_register = false
  end
end
