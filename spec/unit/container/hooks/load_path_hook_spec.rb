# frozen_string_literal: true

RSpec.describe Dry::System::Container, "Default hooks / Load path" do
  let(:container) {
    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/test")
      end
    }
  }

  before do
    @load_path_before = $LOAD_PATH
  end

  after do
    $LOAD_PATH.replace(@load_path_before)
  end

  context "component_dirs configured with add_to_load_path = true" do
    before do
      container.configure do |config|
        config.component_dirs.add "lib" do |dir|
          dir.add_to_load_path = true
        end
      end
    end

    it "adds the component dirs to the load path" do
      expect { container.configured! }
        .to change { $LOAD_PATH.include?(SPEC_ROOT.join("fixtures/test/lib").to_s) }
        .from(false).to(true)
    end
  end

  context "component_dirs configured with add_to_load_path = false" do
    before do
      container.configure do |config|
        config.component_dirs.add "lib" do |dir|
          dir.add_to_load_path = false
        end
      end
    end

    it "does not change the load path" do
      expect { container.configure do; end }.not_to(change { $LOAD_PATH })
    end
  end
end
