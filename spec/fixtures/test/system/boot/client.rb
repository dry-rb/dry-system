# frozen_string_literal: true

Test::Container.register_bootable(:client) do
  use :logger

  Client = Struct.new(:logger)

  register(:client, Client.new(logger))
end
