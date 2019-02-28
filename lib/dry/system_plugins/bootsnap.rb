require 'bootsnap'

module Dry
  module SystemPlugins
    class Bootsnap
      DEFAULT_OPTIONS = {
        load_path_cache: true,
        disable_trace: true,
        compile_cache_iseq: true,
        compile_cache_yaml: true,
        autoload_paths_cache: false
      }.freeze

      def initialize(container, config)
        @container = container
        @container.class_exec do
          setting :bootsnap, DEFAULT_OPTIONS
        end
      end

      def after_configure(config)
        return unless bootsnap_available?
        ::Bootsnap.setup(@container.config.bootsnap.merge(cache_dir: @container.root.join('tmp/cache').to_s))
      end

      # @api private
      def bootsnap_available?
        RUBY_ENGINE == "ruby" && RUBY_VERSION >= "2.3.0" && RUBY_VERSION < "2.5.0"
      end
    end
  end
end
