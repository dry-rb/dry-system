require "dry/system/config/component_dirs"
require "dry/system/config/component_dir"

RSpec.describe Dry::System::Config::ComponentDirs do
  subject(:component_dirs) { described_class.new }

  describe "#add" do
    context "adding and configuring a component dir" do
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
    end

    context "adding an already-configured component dir" do
      it "adds the component dir" do
        component_dir = Dry::System::Config::ComponentDir.new("test/path") do |dir|
          dir.auto_register = false
          dir.add_to_load_path = false
        end

        expect { component_dirs.add component_dir }
          .to change { component_dirs.dirs.keys.length }
          .from(0)
          .to(1)

        expect(component_dirs.dirs["test/path"]).to eql component_dir
      end
    end
  end
end
