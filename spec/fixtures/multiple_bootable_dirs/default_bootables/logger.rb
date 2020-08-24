# frozen_string_literal: true

Test::Container.boot(:logger) do
  start do
    register(:logger, "default_logger")
  end
end
