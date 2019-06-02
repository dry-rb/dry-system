# frozen_string_literal: true

module Test
  class Foo
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end
end
