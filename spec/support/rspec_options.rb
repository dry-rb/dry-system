# frozen_string_literal: true

RSpec.configure do |config|
  config.disable_monkey_patching!

  # When no filter given, search and run focused tests
  config.filter_run_when_matching :focus

  # Run ruby in verbose mode
  config.warnings = true

  # Collect all failing expectations automatically,
  # without calling aggregate_failures everywhere
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end
end
