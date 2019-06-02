# frozen_string_literal: true

module Multiple
  module Level
    class Baz
      include Test::Container.injector["foz"]
    end
  end
end
