Test::Container.boot(:database, from: :bacon) do |app|
  configure do |config|
    config.database_url = 'http://example.com'
  end
end
