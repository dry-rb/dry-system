# frozen_string_literal: true

Test::Container.register_provider(:logger) do
  prepare do
    require "logger"
  end

  start do
    register(:logger, Logger.new(target_container.root.join("log/test.log")))
  end
end
