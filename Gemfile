# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

# Remove verson constraint once latter versions release their -java packages
gem "bootsnap"
gem "dotenv"
gem "dry-events"
gem "dry-monitor"
gem "dry-types"

gem "zeitwerk"

group :test do
  gem "ostruct"
end
