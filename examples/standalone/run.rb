require_relative 'system/container'

App.finalize!

user_repo = App['user_repo']

puts user_repo.db.inspect
