require 'logger'
require 'dry/system/plugins/plugin'

module Dry
  module SystemPlugins
    class Logger < Dry::System::Plugin
      config.identifier = :logger

      def initialize(*args)
        super

        container.setting :logger
        container.setting :logging do
          setting :log_dir, 'log'
          setting :log_levels, {
            development: ::Logger::DEBUG,
            test: ::Logger::DEBUG,
            production: ::Logger::ERROR
          }
          setting :logger_class, ::Logger, reader: true
        end
      end

      def after_configure(config)
        @config = config
        @logger = config.logger ||= config.logging.logger_class.new(log_file)
        @logger.level = log_level

        container.register(:logger, @logger)
      end

      def log_level
        config.logging.log_levels.fetch(config.env, ::Logger::ERROR)
      end

      def log_path
        config.root.join(config.logging.log_dir).realpath
      end

      def log_file
        log_path.join("#{config.env}.log")
      end

      def instance
        @logger
      end
    end
  end
end
