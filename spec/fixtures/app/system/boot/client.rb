# frozen_string_literal: true

Test::Container.register_provider(:client) do |container|
  module Test
    class Client
    end
  end

  container.register(:client, Test::Client.new)
end
