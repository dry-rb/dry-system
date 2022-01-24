# frozen_string_literal: true

RSpec.describe "Auto-registration / Custom instance proc" do
  before :context do
    with_directory(@dir = make_tmp_directory) do
      write "lib/foo.rb", <<~RUBY
        module Test
          class Foo; end
        end
      RUBY
    end
  end

  let(:container) {
    root = @dir
    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = root

        config.component_dirs.add "lib" do |dir|
          dir.namespaces.add_root const: "test"
          dir.instance = proc do |component, *args|
            # Return the component's string key as its instance
            component.key
          end
        end
      end
    }
  }

  shared_examples "custom instance proc" do
    it "registers the component using the custom loader" do
      expect(container["foo"]).to eq "foo"
    end
  end

  context "Non-finalized container" do
    include_examples "custom instance proc"
  end

  context "Finalized container" do
    before do
      container.finalize!
    end

    include_examples "custom instance proc"
  end
end
