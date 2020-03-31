# frozen_string_literal: true

Test::Container.namespace(:test) do |container|
  container.boot(:bar) do
    init do
      module Test
        module Bar
          # I shall be booted
        end
      end
    end

    start do
      container.register(:bar, "I was finalized")
    end
  end
end
