require 'dry/system/components/external'

module Dry
  module System
    class Provider
      attr_reader :identifier

      attr_reader :options

      attr_reader :components

      def initialize(identifier, options)
        @identifier = identifier
        @options = options
        @components = {}
      end

      def boot_path
        options.fetch(:boot_path)
      end

      def boot_files
        Dir[boot_path.join('**/*.rb')]
      end

      def register_component(name, fn)
        components[name] = Components::External.new(name, fn)
      end

      def boot_file(name)
        boot_files.detect { |path| Pathname(path).basename('.rb').to_s == name.to_s }
      end

      def component(name, options = {})
        require boot_file(name)
        components.fetch(name).with(options)
      end
    end
  end
end
