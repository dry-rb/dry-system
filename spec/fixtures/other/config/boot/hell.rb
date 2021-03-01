# frozen_string_literal: true

Test::Container.register_bootable(:heaven) do |_container|
  register("heaven", "string")
end
