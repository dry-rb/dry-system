# frozen_string_literal: true

Test::Container.register_provider(:logger) do |container|
  init do
    require "logger"
  end

  start do
    register(:logger, Logger.new(container.root.join("log/test.log")))
  end
end
