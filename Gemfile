# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/dry-rb/#{repo_name}" }

gemspec

gem 'bootsnap'
gem 'dry-monitor'

gem 'codeclimate-test-reporter', platforms: :mri

group :tools do
  gem 'pry-byebug', platforms: :mri
  gem 'ossy', git: 'https://github.com/solnic/ossy.git', branch: 'master'
end

group :test do
  gem 'warning'
end
