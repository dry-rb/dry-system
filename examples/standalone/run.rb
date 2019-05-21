require 'bundler/setup'
require_relative 'system/container'
require 'dry/events'
require 'dry/monitor/notifications'

App.finalize!

p App.keys

$events = []

App[:notifications].subscribe(:resolved_dependency) do |event|
  p event
end

App['service_with_dependency']
user_repo = App['user_repo']

puts user_repo.db.inspect

