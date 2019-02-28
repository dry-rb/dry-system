require 'dry-configurable'

module Dry
  module System
    class Plugin
      extend Dry::Configurable

      setting :identifier, reader: true
      setting :reader, true, reader: true

      attr_reader :container, :config

      def initialize(container, config)
        @container = container
      end

      def instance
        self
      end
    end
  end
end
