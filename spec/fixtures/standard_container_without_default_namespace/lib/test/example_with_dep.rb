# frozen_string_literal: true

module Test
  class ExampleWithDep
    include Import["test.dep"]
  end
end
