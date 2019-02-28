Test::AnotherContainer.boot(:statistics) do |app|
  start do
    app.register(:statistics, 'external statistics')
  end
end
