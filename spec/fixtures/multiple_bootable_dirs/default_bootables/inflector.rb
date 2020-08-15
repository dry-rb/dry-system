# frozen_string_literal: true

Test::Container.boot(:inflector) do
  start do
    register(:inflector, "default_inflector")
  end
end
