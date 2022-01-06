# frozen_string_literal: true

Test::Container.register_provider(:logger) do
  start do
    register(:logger, "default_logger")
  end
end
