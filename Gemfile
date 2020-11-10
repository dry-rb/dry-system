# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

gem "bootsnap"
gem "dry-monitor"
gem "dry-configurable", path: "../dry-configurable"
gem "zeitwerk"

group :tools do
  gem "pry-byebug", platforms: :mri
end
