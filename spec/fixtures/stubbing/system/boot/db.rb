# frozen_string_literal: true

Test::Container.register_bootable(:db) do |container|
  module Test
    class DB
    end
  end

  container.register(:db, Test::DB.new)
end
