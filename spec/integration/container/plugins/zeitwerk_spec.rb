# frozen_string_literal: true

require "dry/system/container"

RSpec.describe "Zeitwerk plugin" do
  include ZeitwerkHelpers

  after { teardown_zeitwerk }

  specify "Resolving components using Zeitwerk" do
    app = Class.new(Dry::System::Container) do
      use :zeitwerk

      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/zeitwerk").realpath

        config.component_dirs.add "lib" do |dir|
          dir.namespaces.add "test", key: nil
        end
      end
    end

    foo = app["foo"]
    entity = foo.call

    expect(foo).to be_a Test::Foo
    expect(entity).to be_a Test::Entities::FooEntity
  end

  specify "Error is thrown when add_to_load_path is true" do
    expect do
      Class.new(Dry::System::Container) do
        use :zeitwerk

        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/zeitwerk").realpath

          config.component_dirs.add "lib" do |dir|
            dir.add_to_load_path = true
          end
        end
      end
    end.to raise_error(Dry::System::ZeitwerkAddToLoadPathError)
  end
end
