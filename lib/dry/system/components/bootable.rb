module Dry
  module System
    module Components
      class Bootable
        attr_reader :identifier

        attr_reader :fn

        attr_reader :options

        def initialize(identifier, fn, options = {})
          @identifier = identifier
          @fn = fn
          @options = options
        end

        def to_proc
          fn
        end

        def container
          options.fetch(:container)
        end

        def external?
          false
        end

        def key
          options.fetch(:key, identifier)
        end

        def with(new_options)
          self.class.new(identifier, fn, options.merge(new_options))
        end

        def boot_file
          container_boot_files.
            detect { |path| Pathname(path).basename('.rb').to_s == identifier.to_s }
        end

        def boot_path
          container.boot_path
        end

        def container_boot_files
          Dir[container.boot_path.join('**/*.rb')]
        end

        def ensure_valid_boot_file
          raise ComponentFileMismatchError, self unless boot_file
        end
      end
    end
  end
end
