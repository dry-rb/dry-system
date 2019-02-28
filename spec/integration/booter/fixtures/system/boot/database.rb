Test::BootFile = :exists

Test::Container.boot(:database) do |app|
  init do
    register(:database, 'I am a database')
  end
end
