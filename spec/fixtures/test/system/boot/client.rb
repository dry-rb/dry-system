# frozen_string_literal: true

Test::Container.boot(:client) do
  use :logger

  Client = Struct.new(:logger)

  register(:client, Client.new(logger))
end
