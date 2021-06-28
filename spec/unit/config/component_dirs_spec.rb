require "dry/system/config/component_dirs"
require "dry/system/config/component_dir"

RSpec.describe Dry::System::Config::ComponentDirs do
  subject(:component_dirs) { described_class.new }

  describe "#add" do
    it "adds the component dir based on the provided configuration" do
      expect {
        component_dirs.add "test/path" do |dir|
          dir.auto_register = false
          dir.add_to_load_path = false
        end
      }
        .to change { component_dirs.dirs.keys.length }
        .from(0).to(1)

      dir = component_dirs.dirs["test/path"]

      expect(dir.path).to eq "test/path"
      expect(dir.auto_register).to eq false
      expect(dir.add_to_load_path).to eq false
    end

    it "applies default values configured before adding" do
      component_dirs.namespaces = ["global_default"]

      component_dirs.add "test/path"

      dir = component_dirs.dirs["test/path"]
      expect(dir.namespaces).to eq [["global_default", "global_default"]]
    end

    it "applies default values configured after adding" do
      component_dirs.add "test/path"

      component_dirs.namespaces = ["global_default"]

      dir = component_dirs.dirs["test/path"]
      expect(dir.namespaces).to eq [["global_default", "global_default"]]
    end

    it "does not apply default values over the component dir's own config" do
      component_dirs.namespaces = ["global_default"]
      component_dirs.memoize = true

      component_dirs.add "test/path" do |dir|
        dir.namespaces = [nil] # this is the default value
        dir.memoize = false
      end

      dir = component_dirs.dirs["test/path"]

      expect(dir.namespaces).to eq [[nil, nil]] # FIXME this is super awkward
      expect(dir.memoize).to be false
    end

    context "component dir already added" do
      before do
        component_dirs.add "test/path"
      end

      it "raises an error" do
        expect { component_dirs.add "test/path" }.to raise_error(Dry::System::ComponentDirAlreadyAddedError, %r{test/path})
      end
    end
  end
end
