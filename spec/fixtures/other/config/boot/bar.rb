# frozen_string_literal: true

Test::Container.register_provider(:bar, namespace: "test") do |_container|
  prepare do
    module Test
      module Bar
        # I shall be booted
      end
    end
  end

  start do
    register(:bar, "I was finalized")
  end
end
