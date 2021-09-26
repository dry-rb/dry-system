# frozen_string_literal: true

require "bundler/setup"

require "pathname"
require "warning"

begin
  require "byebug"
  require "pry-byebug"
rescue LoadError; end
SPEC_ROOT = Pathname(__FILE__).dirname

Dir[SPEC_ROOT.join("support/*.rb").to_s].sort.each { |f| require f }
Dir[SPEC_ROOT.join("shared/*.rb").to_s].sort.each { |f| require f }

require "dry/system/container"
require "dry/system/stubs"
require "dry/events"

# For specs that rely on `settings` DSL
module Types
  include Dry::Types()
end

RSpec.configure do |config|
  config.after do
    Dry::System.providers.items.delete_if { |p| p.identifier != :system }
  end
end
