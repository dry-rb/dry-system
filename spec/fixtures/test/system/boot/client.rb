Test::Container.finalize(:client) do |container|
  use :logger

  Client = Struct.new(:logger)

  container.register(:client, Client.new(logger))
end
