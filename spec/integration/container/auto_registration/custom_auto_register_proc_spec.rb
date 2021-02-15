RSpec.describe "Auto-registration / Custom auto_register proc" do
  before do
    class Test::Container < Dry::System::Container
      configure do |config|
        config.root = SPEC_ROOT.join("fixtures").realpath

        config.component_dirs.add "components" do |dir|
          dir.default_namespace = "test"
          dir.auto_register = proc do |component|
            !component.path.match?(/bar/)
          end
        end
      end
    end
  end

  shared_examples "custom auto_register proc" do
    it "registers components according to the custom auto_register proc" do
      expect(Test::Container.key?("foo")).to be true
      expect(Test::Container.key?("bar")).to be false
      expect(Test::Container.key?("bar.baz")).to be false
    end
  end

  context "Finalized container" do
    before do
      Test::Container.finalize!
    end

    include_examples "custom auto_register proc"
  end

  context "Non-finalized container" do
    include_examples "custom auto_register proc"
  end
end
