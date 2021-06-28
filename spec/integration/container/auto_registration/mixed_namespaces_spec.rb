# frozen_string_literal: true

RSpec.describe "Auto-registration / Components with mixed namespaces" do
  before do
    class Test::Container < Dry::System::Container
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/mixed_namespaces").realpath

        config.component_dirs.add "lib" do |dir|
          dir.namespaces = ["test.my_app"]
        end
      end
    end
  end

  it "loads components with and without the default namespace (lazy loading)" do
    aggregate_failures do
      expect(Test::Container["app_component"]).to be_an_instance_of Test::MyApp::AppComponent
      expect(Test::Container["test.external.external_component"]).to be_an_instance_of Test::External::ExternalComponent
    end
  end

  it "loads components with and without the default namespace (finalizing)" do
    Test::Container.finalize!

    aggregate_failures do
      expect(Test::Container["app_component"]).to be_an_instance_of Test::MyApp::AppComponent
      expect(Test::Container["test.external.external_component"]).to be_an_instance_of Test::External::ExternalComponent
    end
  end
end
