# encoding: utf-8

if RUBY_ENGINE == 'rbx'
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

begin
  require 'byebug'
rescue LoadError; end

SPEC_ROOT = Pathname(__FILE__).dirname

Dir[SPEC_ROOT.join('support/*.rb').to_s].each { |f| require f }
Dir[SPEC_ROOT.join('shared/*.rb').to_s].each { |f| require f }

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
    Object.const_set(:Test, Module.new { |m| m.extend(TestNamespace) })
  end

  config.after do
    ($LOAD_PATH - @load_paths).each do |path|
      $LOAD_PATH.delete(path)
    end
    Test.remove_constants
    Object.send(:remove_const, :Test)
  end
end
