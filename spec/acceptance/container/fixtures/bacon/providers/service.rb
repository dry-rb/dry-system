module Test
  module Bacon
    register_provider(:service) do |app|
      use bacon: :dep

      start do
        register(:service, app[:dep])
      end
    end
  end
end
