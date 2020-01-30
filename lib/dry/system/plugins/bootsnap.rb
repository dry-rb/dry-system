# frozen_string_literal: true

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
          system.before(:configure) { setting :bootsnap, DEFAULT_OPTIONS }
          system.after(:configure, &:setup_bootsnap)
        end

        # @api private
        def self.dependencies
          { bootsnap: 'bootsnap' }
        end

        # Set up bootsnap for faster booting
        #
        # @api public
        def setup_bootsnap
          return unless bootsnap_available?

          ::Bootsnap.setup(config.bootsnap.merge(cache_dir: root.join('tmp/cache').to_s))
        end

        # @api private
        def bootsnap_available?
          RUBY_ENGINE == 'ruby' && RUBY_VERSION >= '2.3.0' && RUBY_VERSION < '2.5.0'
        end
      end
    end
  end
end
