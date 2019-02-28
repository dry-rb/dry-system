module Test
  Strategy = Struct.new(:name)
end

Test::Container.namespace(:strategies) do |container|
  container.register(:loose, Test::Strategy.new(:loose))
  container.register(:strict) { Test::Strategy.new(:strict)}
end
