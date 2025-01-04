# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

# Remove verson constraint once latter versions release their -java packages
gem "bootsnap", "= 1.4.9"
gem "dotenv"
gem "dry-events", github: "dry-rb/dry-events"
gem "dry-monitor", github: "dry-rb/dry-monitor"
gem "dry-types", github: "dry-rb/dry-types"

gem "dry-auto_inject", github: "dry-rb/dry-auto_inject"
gem "dry-configurable", github: "dry-rb/dry-configurable"
gem "dry-core", github: "dry-rb/dry-core"
gem "dry-inflector", github: "dry-rb/dry-inflector"
gem "dry-logic", github: "dry-rb/dry-logic"

gem "zeitwerk"

group :test do
  gem "ostruct"
end
