# frozen_string_literal: true

module Dry
  module System
    module Plugins
      module Bootsnap
        DEFAULT_OPTIONS = {
          load_path_cache: false,
          compile_cache_iseq: true,
          compile_cache_yaml: true,
        }.freeze

        # @api private
        def self.extended(system)
          super

          system.use(:env)
          system.setting :bootsnap, default: DEFAULT_OPTIONS
          system.after(:configure, &:setup_bootsnap)
        end

        # @api private
        def self.dependencies
          {bootsnap: "bootsnap"}
        end

        # Set up bootsnap for faster booting
        #
        # @api public
        def setup_bootsnap
          return unless bootsnap_available?

          ::Bootsnap.setup(**config.bootsnap.merge(cache_dir: root.join("tmp/cache").to_s))
        end

        # @api private
        def bootsnap_available?
          RUBY_ENGINE == "ruby" && RUBY_VERSION >= "3.0.0"
        end
      end
    end
  end
end
