# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

gem "dry-configurable", git: "https://github.com/dry-rb/dry-configurable", branch: "master"

# Remove verson constraint once latter versions release their -java packages
gem "bootsnap", "= 1.4.9"
gem "dry-monitor"
gem "zeitwerk"

group :tools do
  gem "pry-byebug", platforms: :mri
end
