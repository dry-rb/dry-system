RSpec.describe "Lazy loading components with auto-registration disabled" do
  before do
    module Test
      class Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/lazy_loading/auto_registration_disabled").realpath
          config.component_dirs.add "lib"
        end
      end
    end
  end

  it "does not load the component" do
    expect(Test::Container["fetch_kitten"]).to be
    expect { Test::Container["entities.kitten"] }.to raise_error(Dry::System::ComponentLoadError)
  end
end
