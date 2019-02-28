Test::Container.boot(:settings) do |app|
  settings do
    key :location, Types::String
  end

  configure do |config|
    config.location = "North Pole, AK"
  end

  start do
    register(:settings, config)
  end
end
