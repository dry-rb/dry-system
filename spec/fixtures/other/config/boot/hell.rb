Test::Container.boot(:heaven) do |container|
  register('heaven', 'string')
end
