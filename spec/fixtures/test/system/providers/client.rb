# frozen_string_literal: true

Test::Container.register_provider(:client) do
  start do
    use :logger

    Test::Client = Struct.new(:logger)

    register(:client, Test::Client.new(target_container["logger"]))
  end
end
