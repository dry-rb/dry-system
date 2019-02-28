require 'bacon/in_memory_store'

module Test
  module Bacon
    register_provider(:in_memory) do |app|
      boot do
        register(:in_memory, InMemoryStore.new)
      end

      init do
        app[:in_memory].init!
      end

      start do
        app[:in_memory].start!
      end

      stop do
        app[:in_memory].stop!
      end
    end
  end
end
