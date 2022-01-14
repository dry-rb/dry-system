# frozen_string_literal: true

Test::Container.register_provider(:kitten_service, namespace: true) do
  prepare do
    module KittenService
      class Client
      end
    end
  end

  start do
    register "client", KittenService::Client.new
  end
end
