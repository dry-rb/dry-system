Test::Container.boot(:router, from: :bacon) do |app|
  before(:start) do
    Test::Bacon::Router.config.locale = app.config.locale
  end

  after(:start) do
    container[:router].add_route(:hello_world, 'Hello, world!')
  end
end
