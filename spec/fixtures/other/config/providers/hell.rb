# frozen_string_literal: true

Test::Container.register_provider(:heaven) do
  start do
    register("heaven", "string")
  end
end
