# frozen_string_literal: true

require "dry/system/container"

RSpec.describe Dry::System::Container, "Load path handling" do
  let(:container) {
    class Test::Container < Dry::System::Container
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/test")
        config.component_dirs.add "lib"
      end
    end

    Test::Container
  }

  before do
    @load_path_before = $LOAD_PATH
  end

  after do
    $LOAD_PATH.replace(@load_path_before)
  end

  describe ".add_to_load_path!" do
    it "adds the given directories, relative to the container's root, to the beginning of the $LOAD_PATH" do
      expect { container.add_to_load_path!("lib", "system") }
        .to change { $LOAD_PATH.include?(SPEC_ROOT.join("fixtures/test/lib").to_s) }
        .from(false).to(true)
        .and change { $LOAD_PATH.include?(SPEC_ROOT.join("fixtures/test/system").to_s) }
        .from(false).to(true)

      expect($LOAD_PATH[0..1].sort).to eq [
        SPEC_ROOT.join("fixtures/test/lib").to_s,
        SPEC_ROOT.join("fixtures/test/system").to_s
      ]
    end
  end
end
