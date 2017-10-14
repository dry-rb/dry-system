Test::Container.boot(:client) do |container|
  module Test
    class Client
    end
  end

  container.register(:client, Test::Client.new)
end
