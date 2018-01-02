module Dry
  module System
    module Plugins
      module Bootsnap
        DEFAULT_OPTIONS = {
          load_path_cache: true,
          disable_trace: true,
          compile_cache_iseq: true,
          compile_cache_yaml: true,
          autoload_paths_cache: false
        }.freeze

        # @api private
        def self.extended(system)
          super
          system.use(:env)
          system.setting :bootsnap, DEFAULT_OPTIONS
          system.after(:configure, &:setup_bootsnap)
        end

        # Set up bootsnap for faster booting
        #
        # @api private
        def setup_bootsnap
          require 'bootsnap' unless Object.const_defined?(:Bootsnap)
          ::Bootsnap.setup(config.bootsnap.merge(cache_dir: root.join('tmp/cache').to_s))
        end
      end
    end
  end
end
