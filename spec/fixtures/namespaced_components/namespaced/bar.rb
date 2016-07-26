module Namespaced
  class Bar
    include Test::Container.injector["foo"]
  end
end
