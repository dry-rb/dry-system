# encoding: utf-8

if RUBY_ENGINE == 'ruby' && RUBY_VERSION >= '2.3'
  require 'simplecov'
  SimpleCov.start
end

begin
  require 'byebug'
rescue LoadError; end

SPEC_ROOT = Pathname(__FILE__).dirname

Dir[SPEC_ROOT.join('support/*.rb').to_s].each { |f| require f }
Dir[SPEC_ROOT.join('shared/*.rb').to_s].each { |f| require f }

require 'dry/system/container'
require 'dry/system/stubs'

module TestNamespace
  def remove_constants
    constants.each do |name|
      remove_const(name)
    end
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.before do
    @load_paths = $LOAD_PATH.dup
    @loaded_features = $LOADED_FEATURES.dup
    Object.const_set(:Test, Module.new { |m| m.extend(TestNamespace) })
  end

  config.after do
    ($LOAD_PATH - @load_paths).each do |path|
      $LOAD_PATH.delete(path)
    end
    ($LOADED_FEATURES - @loaded_features).each do |file|
      $LOADED_FEATURES.delete(file)
    end

    Test.remove_constants
    Object.send(:remove_const, :Test)

    Dry::System.instance_variable_set('@__providers__', Dry::System::ProviderRegistry.new)
  end
end
