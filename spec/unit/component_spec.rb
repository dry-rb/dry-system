# frozen_string_literal: true

require "dry/system/component"
require "dry/system/loader"

RSpec.describe Dry::System::Component do
  subject(:component) { Dry::System::Component.new(name, loader: loader_class) }
  let(:loader_class) { Dry::System::Loader }

  describe ".new" do
    it "allows to have the same key multiple times in the identifier/path" do
      component = Dry::System::Component.new("foo.bar.foo", namespace: "foo")
      expect(component.identifier).to eql("bar.foo")
    end

    it "removes only the initial part from the identifier/path" do
      component = Dry::System::Component.new("foo.bar.foo.user.foo.bar", namespace: "foo.bar.foo")
      expect(component.identifier).to eql("user.foo.bar")
    end

    it "returns the identifier if namespace is not present" do
      component = Dry::System::Component.new("foo", namespace: "admin")
      expect(component.identifier).to eql("foo")
    end

    it "allows namespace to collide with the identifier" do
      component = Dry::System::Component.new(:mailer, namespace: "mail", separator: ".")
      expect(component.identifier).to eql("mailer")
    end
  end

  context "when name is a symbol" do
    let(:name) { :foo }

    describe "#identifier" do
      it "returns qualified identifier" do
        expect(component.identifier).to eql("foo")
      end
    end

    describe "#namespace" do
      it "returns configured namespace" do
        expect(component.namespace).to be(nil)
      end
    end

    describe "#root_key" do
      it "returns component key" do
        expect(component.root_key).to be(:foo)
      end
    end

    describe "#instance" do
      it "builds an instance" do
        class Foo; end
        expect(component.instance).to be_instance_of(Foo)
        Object.send(:remove_const, :Foo)
      end
    end
  end

  shared_examples_for "a valid component" do
    describe "#identifier" do
      it "returns qualified identifier" do
        expect(component.identifier).to eql("test.foo")
      end
    end

    describe "#namespace" do
      it "returns configured namespace" do
        expect(component.namespace).to be(nil)
      end
    end

    describe "#namespaced" do
      it "returns a namespaced component" do
        namespaced = component.namespaced(:test)

        expect(namespaced.identifier).to eql("foo")
        expect(namespaced.path).to eql("test/foo")
      end
    end

    describe "#root_key" do
      it "returns component key" do
        expect(component.root_key).to be(:test)
      end
    end

    describe "#instance" do
      it "builds an instance" do
        module Test; class Foo; end; end
        expect(component.instance).to be_instance_of(Test::Foo)
      end
    end
  end

  context "when name is a path" do
    let(:name) { "test/foo" }

    it_behaves_like "a valid component"
  end

  context "when name is a qualified string identifier" do
    let(:name) { "test.foo" }

    it_behaves_like "a valid component"
  end

  context "when name is a qualified symbol identifier" do
    let(:name) { :'test.foo' }

    it_behaves_like "a valid component"
  end
end
