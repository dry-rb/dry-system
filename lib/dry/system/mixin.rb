require 'concurrent/map'
require 'dry/system'
require 'dry/system/provider'
require 'dry-configurable'

module Dry
  module System
    module Mixin
      include Dry::Configurable

      setting(:identifier) { |id| id.to_sym }
      setting :boot_path
      setting :auto_register, true

      def self.extended(klass)
        super

        _settings = self._settings
        klass.class_eval do
          @config = _settings.create_config
        end

        Dry::System.auto_register_system(klass)
      end

      def [](identifier)
        providers.fetch(identifier)
      end

      def providers
        @providers ||= Concurrent::Map.new
      end

      def register_provider(identifier, &fn)
        providers[identifier] = Provider.new(identifier, config.identifier, definition: fn)
      end

      def boot_files
        Dir[config.boot_path.join("**/#{RB_GLOB}")]
      end

      def load_providers
        boot_files.each { |f| require f } if config.boot_path
        self
      end
    end
  end
end
