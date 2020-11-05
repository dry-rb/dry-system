# frozen_string_literal: true

require "bundler/setup"
require_relative "system/container"

require "break"

# App.finalize!

user_repo = App["user_repo"]
p user_repo

p user_repo.user
