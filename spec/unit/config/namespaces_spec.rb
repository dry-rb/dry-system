# frozen_string_literal: true

require "dry/system/config/namespaces"
require "dry/system/config/namespace"

RSpec.describe Dry::System::Config::Namespaces do
  subject(:namespaces) { described_class.new }

  describe "#namespace" do
    it "returns the previously configured namespace for the given path" do
      added_namespace = namespaces.add "test/path", key: "key_ns", const: "const_ns"

      expect(namespaces.namespace("test/path")).to be added_namespace
    end

    it "returns nil when no namepace was previously configured for the given path" do
      expect(namespaces.namespace("test/path")).to be nil
    end
  end

  describe "#[]" do
    it "returns the previously configured namespace for the given path" do
      added_namespace = namespaces.add "test/path", key: "key_ns", const: "const_ns"

      expect(namespaces["test/path"]).to be added_namespace
    end

    it "returns nil when no namepace was previously configured for the given path" do
      expect(namespaces["test/path"]).to be nil
    end
  end

  describe "#root" do
    it "returns the previously configured root namespace" do
      added_root_namespace = namespaces.add_root

      expect(namespaces.root).to be added_root_namespace
    end

    it "returns nil when no root namespace was previously configured" do
      expect(namespaces.root).to be nil
    end
  end

  describe "#add" do
    it "adds the namespace with the given configuration" do
      expect {
        namespaces.add "test/path", key: "key_ns", const: "const_ns"
      }
        .to change { namespaces.length }
        .from(0).to(1)

      ns = namespaces.namespaces["test/path"]

      expect(ns.path).to eq "test/path"
      expect(ns.key).to eq "key_ns"
      expect(ns.const).to eq "const_ns"
    end

    it "raises an exception when a namespace is already added" do
      namespaces.add "test/path"

      expect { namespaces.add "test/path" }.to raise_error(Dry::System::NamespaceAlreadyAddedError, %r{test/path})
    end
  end

  describe "#add_root" do
    it "adds a root namespace with the given configuration" do
      expect {
        namespaces.add_root key: "key_ns", const: "const_ns"
      }
        .to change { namespaces.length }
        .from(0).to(1)

      ns = namespaces.namespaces[nil]

      expect(ns).to be_root
      expect(ns.path).to be_nil
      expect(ns.key).to eq "key_ns"
      expect(ns.const).to eq "const_ns"
    end

    it "raises an exception when a root namespace is already added" do
      namespaces.add_root

      expect { namespaces.add_root }.to raise_error(Dry::System::NamespaceAlreadyAddedError, /root path/)
    end
  end

  describe "#delete" do
    it "deletes and returns the configured namespace for the given path" do
      added_namespace = namespaces.add "test/path"

      deleted_namespace = nil
      expect {
        deleted_namespace = namespaces.delete("test/path")
      }
        .to change { namespaces.length }
        .from(1).to(0)

      expect(deleted_namespace).to be added_namespace
    end

    it "returns nil when no namespace has been configured for the given path" do
      expect(namespaces.delete("test/path")).to be nil
      expect(namespaces).to be_empty
    end
  end

  describe "#delete_root" do
    it "deletes and returns the configured root namespace" do
      added_namespace = namespaces.add_root

      deleted_namespace = nil
      expect {
        deleted_namespace = namespaces.delete_root
      }
        .to change { namespaces.length }
        .from(1).to(0)

      expect(deleted_namespace).to be added_namespace
    end

    it "returns nil when no root namespace has been configured" do
      expect(namespaces.delete_root).to be nil
      expect(namespaces).to be_empty
    end
  end

  describe "#length" do
    it "returns the count of configured namespaces" do
      namespaces.add "test/path_1"
      namespaces.add "test/path_2"
      expect(namespaces.length).to eq 2
    end

    it "returns 0 when there are no configured namespaces" do
      expect(namespaces.length).to eq 0
    end
  end

  describe "#empty?" do
    it "returns true when a namespace has been added" do
      expect { namespaces.add "test/path" }
        .to change { namespaces.empty? }
        .from(true).to(false)
    end
  end

  describe "#to_a" do
    it "returns an array of the configured namespaces, in order of definition" do
      namespaces.add "test/path", key: "test_key_ns"
      namespaces.add_root key: "root_key_ns"

      arr = namespaces.to_a

      expect(arr.length).to eq 2

      expect(arr[0].path).to eq "test/path"
      expect(arr[0].key).to eq "test_key_ns"

      expect(arr[1].path).to eq nil
      expect(arr[1].key).to eq "root_key_ns"
    end

    it "appends a default root namespace if not explicitly configured" do
      namespaces.add "test/path", key: "test_key_ns"

      arr = namespaces.to_a

      expect(arr.length).to eq 2

      expect(arr[0].path).to eq "test/path"
      expect(arr[0].key).to eq "test_key_ns"

      expect(arr[1].path).to be nil
      expect(arr[1].key).to be nil
      expect(arr[1].const).to be nil
    end

    it "includes a default root namespace if no namespaces configured" do
      arr = namespaces.to_a

      expect(arr.length).to eq 1

      expect(arr[0].path).to be nil
      expect(arr[0].key).to be nil
      expect(arr[0].const).to be nil
    end
  end

  describe "#each" do
    it "yields each configured namespace" do
      namespaces.add "test/path", key: "test_key_ns"
      namespaces.add_root key: "root_key_ns"

      expect { |b|
        namespaces.each(&b)
      }.to yield_successive_args(
        an_object_satisfying { |ns| ns.path == "test/path" },
        an_object_satisfying(&:root?)
      )
    end
  end

  describe "#dup" do
    it "dups the registry of namespaces" do
      namespaces.add "test/path", key: "test_key_ns"

      new_namespaces = namespaces.dup

      expect(new_namespaces.to_a).to eq(namespaces.to_a)
      expect(new_namespaces.namespaces).not_to be(namespaces.namespaces)
    end
  end
end
