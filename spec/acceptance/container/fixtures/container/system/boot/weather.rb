Test::Container.boot(:weather) do |app|
  start do
    register(:weather, "In #{app[:settings].location}? Probably cold.")
  end
end
