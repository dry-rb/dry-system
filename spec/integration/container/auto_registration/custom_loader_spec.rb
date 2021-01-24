RSpec.describe "Auto-registration / Custom loader" do
  before do
    # A loader that simply returns the component's identifier string as its instance
    class Test::IdentifierLoader
      def initialize(component)
        @component = component
      end

      def call(*args)
        @component.identifier
      end
    end

    class Test::Container < Dry::System::Container
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures").realpath

        config.component_dirs.add "components" do |dir|
          dir.default_namespace = "test"
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
