require 'dry/system'
require 'dry/system/container/base'

require 'dry/system/container/core_mixin'
require 'dry/system/booter/plugin'
require 'dry/system/importer/plugin'
require 'dry/system/auto_registrar/plugin'
require 'dry/system/manual_registrar/plugin'


module Dry
  module System
    class Container < Base
      extend Core::Mixin

      use Booter::Plugin
      use Importer::Plugin
      use AutoRegistrar::Plugin
      use ManualRegistrar::Plugin
    end
  end
end
