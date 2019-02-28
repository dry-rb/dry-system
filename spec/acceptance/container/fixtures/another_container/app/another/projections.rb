module Test
  module Another
    class Projections
      include Test::AnotherContainer::Inject[:statistics]
    end
  end
end
