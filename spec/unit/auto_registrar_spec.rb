# frozen_string_literal: true

require "dry/system/auto_registrar"
require "dry/system/errors"

RSpec.describe Dry::System::AutoRegistrar, "#finalize!" do
  let(:auto_registrar) { described_class.new(container) }

  let(:container) {
    Class.new(Dry::System::Container) {
      configure! do |config|
        config.root = SPEC_ROOT.join("fixtures").realpath
        config.component_dirs.add "components" do |dir|
          dir.namespaces.add "test", key: nil
        end
      end
    }
  }

  it "registers components in the configured component dirs" do
    auto_registrar.finalize!

    expect(container["foo"]).to be_an_instance_of(Test::Foo)
    expect(container["bar"]).to be_an_instance_of(Test::Bar)
    expect(container["bar.baz"]).to be_an_instance_of(Test::Bar::Baz)

    expect { container["bar.abc"] }.to raise_error(
      Dry::System::ComponentNotLoadableError
    ).with_message(
      <<~ERROR_MESSAGE
        Component 'bar.abc' is not loadable.
        Looking for Test::Bar::Abc.

        You likely need to add:

            acronym('ABC')

        to your container's inflector, since we found a Test::Bar::ABC class.
      ERROR_MESSAGE
    )
  end

  it "doesn't re-register components previously registered via lazy loading" do
    expect(container["foo"]).to be_an_instance_of(Test::Foo)

    expect { auto_registrar.finalize! }.not_to raise_error

    expect(container["bar"]).to be_an_instance_of(Test::Bar)
    expect(container["bar.baz"]).to be_an_instance_of(Test::Bar::Baz)
  end
end
