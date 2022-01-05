# frozen_string_literal: true

Test::Container.register_provider(:heaven) do |_container|
  register("heaven", "string")
end
