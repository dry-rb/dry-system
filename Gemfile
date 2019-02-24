source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

gem 'dry-types', github: 'dry-rb/dry-types', branch: 'rework-schemas'
gem 'dry-struct', github: 'dry-rb/dry-struct', branch: 'update-schemas'

gem 'dry-events', git: 'https://github.com/dry-rb/dry-events.git'
gem 'dry-monitor', git: 'https://github.com/dry-rb/dry-monitor.git'
gem 'bootsnap'

gem 'codeclimate-test-reporter', platforms: :mri

group :tools do
  gem 'byebug', platforms: :mri
end
