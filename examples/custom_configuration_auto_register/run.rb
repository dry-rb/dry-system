# frozen_string_literal: true

require 'bundler/setup'
require_relative 'system/container'

App.finalize!

user_repo = App['user_repo']
puts "User has not been loaded" unless App.key?('entities.user')
puts user_repo.db.inspect
