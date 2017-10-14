Test::Container.boot(:db) do |container|
  module Test
    class DB
    end
  end

  container.register(:db, Test::DB.new)
end
