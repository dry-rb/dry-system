# frozen_string_literal: true

RSpec.describe "Container / Imports / Partial imports" do
  before :context do
    @dir = make_tmp_directory

    with_directory @dir do
      write "lib/private_component.rb", <<~RUBY
        module Test
          class PrivateComponent; end
        end
      RUBY

      write "lib/exportable_component_a.rb", <<~RUBY
        module Test
          class ExportableComponentA; end
        end
      RUBY

      write "lib/nested/exportable_component_b.rb", <<~RUBY
        module Test
          module Nested
            class ExportableComponentB; end
          end
        end
      RUBY
    end
  end

  let(:exporting_container) {
    root = @dir

    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = root
        config.component_dirs.add "lib" do |dir|
          dir.namespaces.add_root const: "test"
        end

        config.exports = [
          "exportable_component_a",
          "nested.exportable_component_b"
        ]
      end
    }
  }

  let(:importing_container) { Class.new(Dry::System::Container) }

  before do
    importing_container.import \
      keys: ["exportable_component_a"], # nah I don't like it
      from: exporting_container,
      as: :other
  end

  context "lazy loading" do
    it "works" do
      expect(importing_container.key?("other.exportable_component_a")).to be true
      expect(importing_container.key?("other.nested.exportable_component_b")).to be false
    end
  end

  context "finalized" do
    before do
      importing_container.finalize!
    end

    it "works" do
      expect(importing_container.key?("other.exportable_component_a")).to be true
      expect(importing_container.key?("other.nested.exportable_component_b")).to be false
    end
  end
end
