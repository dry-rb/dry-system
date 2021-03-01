# frozen_string_literal: true

Test::Container.register_bootable(:inflector) do
  start do
    register(:inflector, "default_inflector")
  end
end
