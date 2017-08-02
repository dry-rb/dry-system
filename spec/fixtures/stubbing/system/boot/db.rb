Test::Container.finalize :db do |container|
  module Test
    class DB
    end
  end

  container.register(:db, Test::DB.new)
end
