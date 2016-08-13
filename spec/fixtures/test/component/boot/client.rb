Test::Container.finalize(:client) do |container|
  uses :logger

  Client = Struct.new(:logger)

  container.register(:client, Client.new(logger))
end
