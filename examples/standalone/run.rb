# frozen_string_literal: true

require "bundler/setup"
require_relative "system/container"
require_relative "system/import"
require "dry/events"
require "dry/monitor/notifications"

App[:notifications].subscribe(:resolved_dependency) do |event|
  puts "Event #{event.id}, payload: #{event.to_h}"
end

App[:notifications].subscribe(:registered_dependency) do |event|
  puts "Event #{event.id}, payload: #{event.to_h}"
end

App.finalize!
p App.keys

App["service_with_dependency"]
user_repo = App["user_repo"]

puts user_repo.db.inspect
