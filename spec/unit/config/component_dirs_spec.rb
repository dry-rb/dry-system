# frozen_string_literal: true

require "dry/system/config/component_dirs"
require "dry/system/config/component_dir"

RSpec.describe Dry::System::Config::ComponentDirs do
  subject(:component_dirs) { described_class.new }

  describe "#dir" do
    it "returns the added dir for the given path" do
      dir = component_dirs.add("test/path")
      expect(component_dirs.dir("test/path")).to be dir
    end

    it "yields the dir" do
      dir = component_dirs.add("test/path")
      expect { |b| component_dirs.dir("test/path", &b) }.to yield_with_args dir
    end

    it "applies global default values configured before retrieval" do
      component_dirs.add("test/path")
      component_dirs.namespaces.add "global_default"
      expect(component_dirs.dir("test/path").namespaces.paths).to eq ["global_default"]
    end

    it "returns nil when no dir was added for the given path" do
      expect(component_dirs.dir("test/path")).to be nil
    end
  end

  describe "#[]" do
    it "returns the added dir for the given path" do
      dir = component_dirs.add("test/path")
      expect(component_dirs["test/path"]).to be dir
    end

    it "yields the dir" do
      dir = component_dirs.add("test/path")
      expect { |b| component_dirs["test/path", &b] }.to yield_with_args dir
    end

    it "applies global default values configured before retrieval" do
      component_dirs.add("test/path")
      component_dirs.namespaces.add "global_default"
      expect(component_dirs["test/path"].namespaces.paths).to eq ["global_default"]
    end

    it "returns nil when no dir was added for the given path" do
      expect(component_dirs["test/path"]).to be nil
    end
  end

  describe "#add" do
    it "adds a component dir by path, with config set on a yielded dir" do
      expect {
        component_dirs.add "test/path" do |dir|
          dir.auto_register = false
          dir.add_to_load_path = false
        end
      }
        .to change { component_dirs.length }
        .from(0).to(1)

      dir = component_dirs["test/path"]

      expect(dir.path).to eq "test/path"
      expect(dir.auto_register).to eq false
      expect(dir.add_to_load_path).to eq false
    end

    it "adds a pre-built component dir" do
      dir = Dry::System::Config::ComponentDir.new("test/path").tap do |d|
        d.auto_register = false
        d.add_to_load_path = false
      end

      expect { component_dirs.add(dir) }
        .to change { component_dirs.length }
        .from(0).to(1)

      expect(component_dirs["test/path"]).to be dir
    end

    it "raises an error when a component dir has already been added for the given path" do
      component_dirs.add "test/path"
      expect { component_dirs.add "test/path" }.to raise_error(Dry::System::ComponentDirAlreadyAddedError, %r{test/path})
    end

    it "raises an error when a component dir has already been added for the given dir's path" do
      component_dirs.add "test/path"
      expect {
        component_dirs.add Dry::System::Config::ComponentDir.new("test/path")
      }
        .to raise_error(Dry::System::ComponentDirAlreadyAddedError, %r{test/path})
    end

    it "applies default values configured before adding" do
      component_dirs.namespaces.add "global_default"

      component_dirs.add "test/path"

      dir = component_dirs["test/path"]
      expect(dir.namespaces.to_a.map(&:path)).to eq ["global_default", nil]
    end

    it "does not apply default values over the component dir's own config" do
      component_dirs.namespaces.add "global_default"
      component_dirs.memoize = true

      component_dirs.add "test/path" do |dir|
        dir.namespaces.add_root # force the default value
        dir.memoize = false
      end

      dir = component_dirs["test/path"]

      expect(dir.namespaces.to_a.map(&:path)).to eq [nil]
      expect(dir.memoize).to be false
    end
  end

  describe "#delete" do
    it "deletes and returns the component dir for the given path" do
      added_dir = component_dirs.add("test/path")

      deleted_dir = nil
      expect { deleted_dir = component_dirs.delete("test/path") }
        .to change { component_dirs.length }
        .from(1).to(0)

      expect(deleted_dir).to be added_dir
    end

    it "returns nil when no component dir has been added for the given path" do
      expect(component_dirs.delete("test/path")).to be nil
      expect(component_dirs.length).to eq 0
    end
  end

  describe "#length" do
    it "returns the count of component dirs" do
      component_dirs.add "test/path_1"
      component_dirs.add "test/path_2"
      expect(component_dirs.length).to eq 2
    end

    it "returns 0 when there are no configured component dirs" do
      expect(component_dirs.length).to eq 0
    end
  end
end
