# frozen_string_literal: true

require 'logger'

module Dry
  module System
    module Plugins
      module Logging
        # @api private
        def self.extended(system)
          system.setting :logger, reader: true

          system.setting :log_dir, 'log'

          system.setting :log_levels,
            development: Logger::DEBUG,
            test: Logger::DEBUG,
            production: Logger::ERROR

          system.setting :logger_class, ::Logger, reader: true

          system.after(:configure, &:register_logger)

          super
        end

        # Set a logger
        #
        # This is invoked automatically when a container is being configured
        #
        # @return [self]
        #
        # @api private
        def register_logger
          if registered?(:logger)
            self
          elsif config.logger
            register(:logger, config.logger)
          else
            config.logger = logger = config.logger_class.new(log_file_path)
            config.logger.level = log_level

            register(:logger, config.logger)
            self
          end
        end

        # @api private
        def log_level
          config.log_levels.fetch(config.env, Logger::ERROR)
        end

        # @api private
        def log_dir_path
          root.join(config.log_dir).realpath
        end

        # @api private
        def log_file_path
          log_dir_path.join(log_file_name)
        end

        # @api private
        def log_file_name
          "#{config.env}.log"
        end
      end
    end
  end
end
