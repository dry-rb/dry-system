# frozen_string_literal: true

require "bundler/setup"
require_relative "system/container"
require_relative "system/import"

App.finalize!

user_repo1 = App["user_repo"]
user_repo2 = App["user_repo"]
puts "User has not been loaded" unless App.key?("entities.user")
puts user_repo1.db.inspect
puts user_repo2.db.inspect
puts "user_repo1 and user_repo2 reference the same instance" if user_repo1.equal?(user_repo2)
