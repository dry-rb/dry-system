# frozen_string_literal: true

RSpec.describe "Auto-registration / Custom loader" do
  before do
    # A loader that simply returns the component's identifier string as its instance
    class Test::IdentifierLoader
      def self.call(component, *_args)
        component.identifier.to_s
      end
    end

    class Test::Container < Dry::System::Container
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures").realpath

        config.component_dirs.add "components" do |dir|
          dir.namespaces.add "test", identifier: nil
          dir.loader = Test::IdentifierLoader
        end
      end
    end
  end

  shared_examples "custom loader" do
    it "registers the component using the custom loader" do
      expect(Test::Container["foo"]).to eq "foo"
    end
  end

  context "Finalized container" do
    before do
      Test::Container.finalize!
    end

    include_examples "custom loader"
  end

  context "Non-finalized container" do
    include_examples "custom loader"
  end
end
