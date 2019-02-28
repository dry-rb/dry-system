module Test
  class Foo
    attr_reader :name

    def initialize(name = '')
      @name = name
    end
  end
end

Test::Container.namespace(:foo) do |container|
  container.register('special') do
    Test::Foo.new('special')
  end
end
