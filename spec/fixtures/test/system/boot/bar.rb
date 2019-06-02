# frozen_string_literal: true

Test::Container.boot(:bar, namespace: 'test') do
  init do
    module Test
      module Bar
        # I shall be booted
      end
    end
  end

  start do
    register(:bar, 'I was finalized')
  end
end
