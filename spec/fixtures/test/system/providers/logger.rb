# frozen_string_literal: true

module Test
  class LoggerProvider < Dry::System::Provider::Source
    def prepare
      require "logger"
    end

    def start
      register(:logger, Logger.new(target_container.root.join("log/test.log")))
    end
  end
end

Test::Container.register_provider(:logger, source: Test::LoggerProvider)
