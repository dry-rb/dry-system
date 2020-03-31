# frozen_string_literal: true

require "bundler/setup"

require_relative "support/coverage"

require "pathname"

require "warning"
# Warning.process { |w| raise RuntimeError, w } unless ENV['NO_WARNING']

begin
  require "byebug"
  require "pry-byebug"
rescue LoadError; end
SPEC_ROOT = Pathname(__FILE__).dirname

Dir[SPEC_ROOT.join("support/*.rb").to_s].each { |f| require f }
Dir[SPEC_ROOT.join("shared/*.rb").to_s].each { |f| require f }

require "dry/system/container"
require "dry/system/stubs"
require "dry/events"

module TestNamespace
  def remove_constants
    constants.each do |name|
      remove_const(name)
    end
  end
end

# for specs that rely on `settings` DSL
module Types
  include Dry::Types()
end

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.before do
    @load_paths = $LOAD_PATH.dup
    @loaded_features = $LOADED_FEATURES.dup
    Object.const_set(:Test, Module.new { |m| m.extend(TestNamespace) })
  end

  config.after do
    $LOAD_PATH.replace(@load_paths)
    $LOADED_FEATURES.replace(@loaded_features)

    Test.remove_constants
    Object.send(:remove_const, :Test)
    Object.send(:remove_const, :Namespaced) if defined? Namespaced

    Dry::System.providers.items.delete_if { |p| p.identifier != :system }
  end
end
