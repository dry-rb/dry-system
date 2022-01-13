# frozen_string_literal: true

Test::Container.register_provider(:db) do
  module Test
    class DB
    end
  end

  start do
    register(:db, Test::DB.new)
  end
end
