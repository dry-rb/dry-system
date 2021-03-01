# frozen_string_literal: true

Test::Container.register_bootable(:logger) do
  start do
    register(:logger, "default_logger")
  end
end
