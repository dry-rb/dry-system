# encoding: utf-8

if RUBY_ENGINE == "rbx"
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

begin
  require 'byebug'
rescue LoadError; end

SPEC_ROOT = Pathname(__FILE__).dirname

Dir[SPEC_ROOT.join('support/*.rb').to_s].each { |f| require f }
Dir[SPEC_ROOT.join('shared/*.rb').to_s].each { |f| require f }

module Test; end

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.before do
    @test_constants = Test.constants
  end

  config.after do
    added_constants = Test.constants - @test_constants
    added_constants.each { |name| Test.send(:remove_const, name) }
  end
end
