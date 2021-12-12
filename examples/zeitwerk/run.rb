# frozen_string_literal: true

require "bundler/setup"
require_relative "system/container"
require_relative "system/import"

App.finalize!

service = App["service_with_dependency"]

puts "Container keys: #{App.keys}"
puts "User repo:      #{service.user_repo.inspect}"
puts "Loader:         #{App.autoloader}"
