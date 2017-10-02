App.boot(:persistence) do |persistence|
  init do
    require 'sequel'
  end

  start do
    persistence.register('persistence.db', Sequel.connect('sqlite::memory'))
  end

  stop do
    db.close_connection
  end
end
