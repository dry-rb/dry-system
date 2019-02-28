require 'bacon/router'

module Test
  module Bacon
    register_provider(:router) do
      start do
        register(:router, Router.new)
      end
    end
  end
end
