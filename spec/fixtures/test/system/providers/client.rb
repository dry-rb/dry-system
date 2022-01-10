# frozen_string_literal: true

Test::Container.register_provider(:client) do
  start do
    use :logger

    Client = Struct.new(:logger)

    register(:client, Client.new(target_container["logger"]))
  end
end
