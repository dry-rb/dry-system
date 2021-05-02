# frozen_string_literal: true

require "dry/system/auto_registrar"

RSpec.describe Dry::System::AutoRegistrar, "#finalize!" do
  let(:auto_registrar) { described_class.new(container) }

  let(:container) {
    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures").realpath
        config.component_dirs.add "components" do |dir|
          dir.default_namespace = "test"
        end
      end
    }
  }

  it "registers components in the configured component dirs" do
    auto_registrar.finalize!

    expect(container["foo"]).to be_an_instance_of(Test::Foo)
    expect(container["bar"]).to be_an_instance_of(Test::Bar)
    expect(container["bar.baz"]).to be_an_instance_of(Test::Bar::Baz)
  end

  it "doesn't re-register components previously registered via lazy loading" do
    expect(container["foo"]).to be_an_instance_of(Test::Foo)

    expect { auto_registrar.finalize! }.not_to raise_error

    expect(container["bar"]).to be_an_instance_of(Test::Bar)
    expect(container["bar.baz"]).to be_an_instance_of(Test::Bar::Baz)
  end
end
