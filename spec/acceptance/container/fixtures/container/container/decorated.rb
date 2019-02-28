require 'delegate'

module Test
  class Decorator < SimpleDelegator
    def to_s
      "Original: #{__getobj__}"
    end
  end
end

Test::Container.decorate(:statistics, with: Decorator)
