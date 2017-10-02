require 'concurrent/map'
require 'dry/system/components/bootable'

module Dry
  module System
    class Provider
      attr_reader :identifier

      attr_reader :options

      attr_reader :components

      def initialize(identifier, options)
        @identifier = identifier
        @options = options
        @components = Concurrent::Map.new
      end

      def boot_path
        options.fetch(:boot_path)
      end

      def boot_files
        Dir[boot_path.join('**/*.rb')]
      end

      def register_component(name, fn)
        components[name] = Components::Bootable.new(name, &fn)
      end

      def boot_file(name)
        boot_files.detect { |path| Pathname(path).basename('.rb').to_s == name.to_s }
      end

      def component(name, options = {})
        components.fetch(name).with(options)
      end

      def load_components
        boot_files.each { |f| require f }
        freeze
        self
      end
    end
  end
end
