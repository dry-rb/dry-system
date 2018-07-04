Test::Container.boot(:kitten_service, namespace: true) do |container|
  init do
    module KittenService
      class Client
      end
    end
  end

  start do
    register "client", KittenService::Client.new
  end
end
