# frozen_string_literal: true

RSpec.describe "Eager loading during finalization" do
  it "raises error when component cannot be found, due to missing inflection" do
    class Test::Container < Dry::System::Container
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures").realpath

        config.component_dirs.add "components" do |dir|
          dir.namespaces.add "test", key: nil
        end
      end
    end
    expect { Test::Container.finalize! }.to raise_error(Dry::System::ComponentNotLoadableError)
  end

  it "does not raise error when constant can be found" do
    class Test::Container < Dry::System::Container
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures").realpath

        config.component_dirs.add "components" do |dir|
          dir.namespaces.add "test", key: nil
        end

        config.inflector = Dry::Inflector.new { |i| i.acronym("ABC") }
      end
    end
    expect { Test::Container.finalize! }.to_not raise_error
  end
end
