# frozen_string_literal: true

Test::Container.register_provider(:client) do
  module Test
    class Client
    end
  end

  start do
    register(:client, Test::Client.new)
  end
end
