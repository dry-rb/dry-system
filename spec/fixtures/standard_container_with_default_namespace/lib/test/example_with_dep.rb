# frozen_string_literal: true

module Test
  class ExampleWithDep
    include Import["dep"]
  end
end
