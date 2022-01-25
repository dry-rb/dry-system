# frozen_string_literal: true

RSpec.describe "Zeitwerk plugin / Resolving components" do
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
end
