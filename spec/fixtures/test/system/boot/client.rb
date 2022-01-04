# frozen_string_literal: true

Test::Container.boot(:client) do |container|
  use :logger

  Client = Struct.new(:logger)

  register(:client, Client.new(container["logger"]))
end
