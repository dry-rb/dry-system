module Multiple
  module Level
    class Baz
      include Test::Container.injector["foz"]
    end
  end
end
