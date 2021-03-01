# frozen_string_literal: true

Test::Container.register_bootable(:heaven) do
  register("heaven", "string")
end
