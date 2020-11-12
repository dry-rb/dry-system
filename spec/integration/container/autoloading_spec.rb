# frozen_string_literal: true

require "dry/system/container"
require "dry/system/loader/autoloading"
require "zeitwerk"

RSpec.describe "Autoloading loader" do
  specify "Resolves components using Zeitwerk" do
    # See https://github.com/jruby/jruby/issues/5638 for current state
    pending "Zeitwerk is not fully functioning on JRuby" if RUBY_PLATFORM == "java"

    module Test
      class Container < Dry::System::Container
        config.root = SPEC_ROOT.join("fixtures/autoloading").realpath
        config.add_component_dirs_to_load_path = false
        config.loader = Dry::System::Loader::Autoloading
        config.default_namespace = "test"
      end
    end

    loader = Zeitwerk::Loader.new
    loader.push_dir Test::Container.config.root.join("lib").realpath
    loader.setup

    foo = Test::Container["foo"]
    entity = foo.call

    expect(foo).to be_a Test::Foo
    expect(entity).to be_a Test::Entities::FooEntity

    teardown_zeitwerk
  end

  def teardown_zeitwerk
    # From zeitwerk's own test/support/loader_test

    Zeitwerk::Registry.loaders.each(&:unload)

    Zeitwerk::Registry.loaders.clear
    Zeitwerk::Registry.loaders_managing_gems.clear

    Zeitwerk::ExplicitNamespace.cpaths.clear
    Zeitwerk::ExplicitNamespace.tracer.disable
  end
end
