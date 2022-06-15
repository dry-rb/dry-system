# frozen_string_literal: true

RSpec.describe "Lazy-loading registration manifest files" do
  before do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/manifest_registration").realpath
        end

        add_to_load_path!("lib")
      end
    end
  end

  shared_examples "manifest component" do
    it "loads a registration manifest file if the component could not be found" do
      expect(Test::Container["foo.special"]).to be_a(Test::Foo)
      expect(Test::Container["foo.special"].name).to eq "special"
    end
  end

  context "Non-finalized container" do
    include_examples "manifest component"
  end

  context "Finalized container" do
    before { Test::Container.finalize! }
    include_examples "manifest component"
  end
end
