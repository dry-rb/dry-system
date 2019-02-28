Test::Container.namespace(:foo) do |container|
  container.register('special') do
    require 'test/foo'
    Test::Foo.new('special')
  end
end
