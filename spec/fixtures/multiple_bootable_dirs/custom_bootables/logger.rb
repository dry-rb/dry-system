# frozen_string_literal: true

Test::Container.register_provider(:logger) do
  start do
    register(:logger, "custom_logger")
  end
end
