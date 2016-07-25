RSpec.describe Dry::Component::Injector do
  before do
    class Test::Container < Dry::Component::Container
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures/test").realpath
      end

      load_paths! "lib"
    end
  end

  it "supports args injection by default" do
    obj = Class.new do
      include Test::Container::Inject["test.dep"]
    end.new

    expect(obj.dep).to be_a Test::Dep
  end

  it "supports args injection with explicit method" do
    obj = Class.new do
      include Test::Container::Inject.args["test.dep"]
    end.new

    expect(obj.dep).to be_a Test::Dep
  end

  it "supports hash injection" do
    obj = Class.new do
      include Test::Container::Inject.hash["test.dep"]
    end.new

    expect(obj.dep).to be_a Test::Dep
  end

  it "support kwargs injection" do
    obj = Class.new do
      include Test::Container::Inject.kwargs["test.dep"]
    end.new

    expect(obj.dep).to be_a Test::Dep
  end

  it "allows injection strategies to be swapped" do
    obj = Class.new do
      include Test::Container::Inject.kwargs.hash["test.dep"]
    end.new

    expect(obj.dep).to be_a Test::Dep
  end

  it "supports aliases" do
    obj = Class.new do
      include Test::Container::Inject[foo: "test.dep"]
    end.new

    expect(obj.foo).to be_a Test::Dep
  end

  context "singleton" do
    it "supports injection" do
      obj = Class.new do
        include Test::Container::Inject[foo: "test.singleton_dep"]
      end.new

      expect(obj.foo).to be_a Test::SingletonDep
    end
  end
end
