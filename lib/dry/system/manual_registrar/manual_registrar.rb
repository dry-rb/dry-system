require 'dry/system/constants'

module Dry
  module System
    module ManualRegistrar
      # Default manual registration implementation
      #
      # This is currently configured by default for every System::Container.
      # Manual registrar objects are responsible for loading files from configured
      # manual registration paths, which should hold code to explicitly register
      # certain objects with the container.
      #
      # @api private
      class ManualRegistrar
        # @api private
        attr_reader :path

        def initialize(path)
          @path = path
        end

        # @api private
        def finalize!
          Dir[path.join(RB_GLOB)].each do |file|
            call(File.basename(file, RB_EXT))
          end
        end

        # @api private
        def call(name)
          name = name.respond_to?(:root_key) ? name.root_key.to_s : name

          require(path.join(name))
        end

        def file_exists?(name)
          name = name.respond_to?(:root_key) ? name.root_key.to_s : name

          path.join("#{name}#{RB_EXT}").exist?
        end
      end
    end
  end
end
