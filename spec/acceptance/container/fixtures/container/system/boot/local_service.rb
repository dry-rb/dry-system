Test::Container.boot(:local_service) do |app|
  use bacon: :dep

  start do
    register(:local_service, app[:dep])
  end
end
