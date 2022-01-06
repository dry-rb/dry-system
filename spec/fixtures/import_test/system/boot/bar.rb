# frozen_string_literal: true

Test::Container.namespace(:test) do |container|
  module Test
    module Bar
      # I shall be booted
    end
  end

  container.register_provider(:bar) do
    container.register(:bar, "I was finalized")
  end
end
