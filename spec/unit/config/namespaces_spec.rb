# frozen_string_literal: true

require "dry/system/config/namespaces"
require "dry/system/config/namespace"

RSpec.describe Dry::System::Config::Namespaces do
  subject(:namespaces) { described_class.new }

  describe "#add" do
    it "adds the namespace with the given configuration" do
      expect {
        namespaces.add "test/path", identifier: "ident_ns", const: "const_ns"
      }
        .to change { namespaces.namespaces.keys.length }
        .from(0).to(1)

      ns = namespaces.namespaces["test/path"]

      expect(ns.path).to eq "test/path"
      expect(ns.identifier_namespace).to eq "ident_ns"
      expect(ns.const_namespace).to eq "const_ns"
    end

    it "raises an exception when a namespace is already added" do
      namespaces.add "test/path"

      expect { namespaces.add "test/path" }.to raise_error(Dry::System::NamespaceAlreadyAddedError, %r{test/path})
    end
  end

  describe "#root" do
    it "adds a root namespace with the given configuration" do
      expect {
        namespaces.root identifier: "ident_ns", const: "const_ns"
      }
        .to change { namespaces.namespaces.keys.length }
        .from(0).to(1)

      ns = namespaces.namespaces[nil]

      expect(ns).to be_root
      expect(ns.path).to be_nil
      expect(ns.identifier_namespace).to eq "ident_ns"
      expect(ns.const_namespace).to eq "const_ns"
    end

    it "raises an exception when a root namespace is already added" do
      namespaces.root

      expect { namespaces.root }.to raise_error(Dry::System::NamespaceAlreadyAddedError, %r{root path})
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
      namespaces.add "test/path", identifier: "test_ident_ns"
      namespaces.root identifier: "root_ident_ns"

      arr = namespaces.to_a

      expect(arr.length).to eq 2

      expect(arr[0].path).to eq "test/path"
      expect(arr[0].identifier_namespace).to eq "test_ident_ns"

      expect(arr[1].path).to eq nil
      expect(arr[1].identifier_namespace).to eq "root_ident_ns"
    end

    it "appends a default root namespace if not explicitly configured" do
      namespaces.add "test/path", identifier: "test_ident_ns"

      arr = namespaces.to_a

      expect(arr.length).to eq 2

      expect(arr[0].path).to eq "test/path"
      expect(arr[0].identifier_namespace).to eq "test_ident_ns"

      expect(arr[1].path).to be nil
      expect(arr[1].identifier_namespace).to be nil
      expect(arr[1].const_namespace).to be nil
    end

    it "includes a default root namespace if no namespaces configured" do
      arr = namespaces.to_a

      expect(arr.length).to eq 1

      expect(arr[0].path).to be nil
      expect(arr[0].identifier_namespace).to be nil
      expect(arr[0].const_namespace).to be nil
    end
  end

  describe "#each" do
    it "yields each configured namespace" do
      namespaces.add "test/path", identifier: "test_ident_ns"
      namespaces.root identifier: "root_ident_ns"

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
      namespaces.add "test/path", identifier: "test_ident_ns"

      new_namespaces = namespaces.dup

      expect(new_namespaces.to_a).to eq(namespaces.to_a)
      expect(new_namespaces.namespaces).not_to eq(namespaces.namespaces)
    end
  end
end
