# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

# Remove verson constraint once latter versions release their -java packages
gem "bootsnap", "= 1.4.9"
gem "dotenv"
gem "dry-auto_inject", github: "dry-rb/dry-auto_inject", branch: "main"
gem "dry-events"
gem "dry-logic", github: "dry-rb/dry-logic", branch: "main"
gem "dry-monitor"
gem "dry-types", github: "dry-rb/dry-types", branch: "main"
gem "zeitwerk"

gem "dry-core", github: "dry-rb/dry-core", branch: "main"

group :tools do
  gem "pry-byebug", platforms: :mri
end
