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
      dir = Dry::System::Config::ComponentDir.new("test/path").tap do |dir|
        dir.auto_register = false
        dir.add_to_load_path = false
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
end
