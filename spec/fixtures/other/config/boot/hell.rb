# frozen_string_literal: true

Test::Container.boot(:heaven) do |_container|
  register("heaven", "string")
end
