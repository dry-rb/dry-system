# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

# Remove verson constraint once latter versions release their -java packages
gem "bootsnap", "= 1.4.9"
gem "dotenv"
gem "dry-monitor"
gem "dry-types"
gem "zeitwerk"

group :tools do
  gem "pry-byebug", platforms: :mri
end
