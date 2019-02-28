require 'dry/system/plugins/plugin'
require 'dry/system_plugins/env/parser'

module Dry
  module SystemPlugins
    module Env
      # @api public
      class Plugin < Dry::System::Plugin
        DEFAULT_INFERRER = -> { :development }

        setting :identifier, :env
        setting :inferrer

        def initialize(*args)
          super

          inferrer = self.class.config.inferrer || DEFAULT_INFERRER

          container.class_exec do
            setting :env, inferrer.call
          end
        end

        def after_configure(config)
          @config = config
        end

        def instance
          @instance ||= env_files.map(&Parser.method(:call)).reduce(:merge)
        end

        def env_files
          [".env", ".env.#{config.env}"]
            .map { |f| config.root.join(f) }
            .find_all(&:exist?)
            .map { |f| File.read(f) }
        end
      end
    end
  end
end
