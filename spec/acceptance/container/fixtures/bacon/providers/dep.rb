require 'bacon/router'

module Test
  module Bacon
    register_provider(:dep) do
      start do
        register(:dep, 'I am a dependency')
      end
    end
  end
end
