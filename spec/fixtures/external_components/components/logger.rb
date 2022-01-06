# frozen_string_literal: true

require "dry/system"

Dry::System.register_source_provider(:logger, group: :external_components) do
  settings do
    key :log_level, Types::Symbol.default(:scream)
  end

  prepare do
    unless defined?(ExternalComponents)
      module ExternalComponents
        class Logger
          class << self
            attr_accessor :default_level
          end

          self.default_level = :scream

          attr_reader :log_level

          def initialize(log_level = Logger.default_level)
            @log_level = log_level
          end
        end
      end
    end
  end

  start do
    logger =
      if config
        ExternalComponents::Logger.new(config.log_level)
      else
        ExternalComponents::Logger.new
      end

    register(:logger, logger)
  end
end
