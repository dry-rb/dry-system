# frozen_string_literal: true

Test::Container.register_provider(:db) do |container|
  module Test
    class DB
    end
  end

  container.register(:db, Test::DB.new)
end
