Test::Container.namespace(:test) do |container|
  container.finalize(:bar) do
    start do
      module Test
        module Bar
          # I shall be booted
        end
      end
    end

    runtime do
      container.register(:bar, 'I was finalized')
    end
  end
end
