# frozen_string_literal: true

Test::Container.register_bootable(:logger) do
  start do
    register(:logger, "custom_logger")
  end
end
