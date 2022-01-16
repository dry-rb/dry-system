# frozen_string_literal: true

RSpec.describe "Container / Imports / Explicit exports" do
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
    exports = self.exports if respond_to?(:exports)

    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = root
        config.component_dirs.add "lib" do |dir|
          dir.namespaces.add_root const: "test"
        end
        config.exports = exports if exports
      end
    }
  }

  let(:importing_container) {
    exporting_container = self.exporting_container

    Class.new(Dry::System::Container) {
      import other: exporting_container
    }
  }

  context "exports configured as a list of keys" do
    let(:exports) {
      %w[
        exportable_component_a
        nested.exportable_component_b
      ]
    }

    context "importing container is lazy loading" do
      it "can import only the components marked as exports" do
        expect(importing_container.key?("other.exportable_component_a")).to be true
        expect(importing_container.key?("other.nested.exportable_component_b")).to be true
        expect(importing_container.key?("other.private_component")).to be false
      end

      it "only loads imported components as required (in both containers)" do
        importing_container["other.exportable_component_a"]

        expect(importing_container.keys).to eq ["other.exportable_component_a"]
        expect(exporting_container.keys).to eq ["exportable_component_a"]
      end
    end

    context "importing container is finalized" do
      before do
        importing_container.finalize!
      end

      it "can import only the components explicitly marked as exports" do
        expect(importing_container.key?("other.exportable_component_a")).to be true
        expect(importing_container.key?("other.nested.exportable_component_b")).to be true
        expect(importing_container.key?("other.private_component")).to be false
      end

      it "does not finalize the exporting container" do
        expect(importing_container.key?("other.exportable_component_a")).to be true
        expect(exporting_container).not_to be_finalized
      end

      it "does not load components not marked for export" do
        expect(exporting_container.keys).to eq [
          "exportable_component_a",
          "nested.exportable_component_b"
        ]
      end
    end
  end

  context "exports configured as an empty array" do
    let(:exports) { [] }

    it "cannot import anything" do
      expect(importing_container.key?("other.exportable_component_a")).to be false
      expect(importing_container.key?("other.nested.exportable_component_b")).to be false
      expect(importing_container.key?("other.private_component")).to be false
    end

    it "does not finalize the exporting container" do
      expect(importing_container.key?("other.exportable_component_a")).to be false
      expect(exporting_container).not_to be_finalized
    end

    it "does not load any components in the exporting container" do
      expect(exporting_container.keys).to be_empty
    end
  end

  context "exports not configured (defaulting to nil)" do
    it "imports all components" do
      expect(importing_container.key?("other.exportable_component_a")).to be true
      expect(importing_container.key?("other.nested.exportable_component_b")).to be true
      expect(importing_container.key?("other.private_component")).to be true
    end

    it "finalizes the exporting container" do
      importing_container.importer.finalize!

      expect(exporting_container).to be_finalized
    end
  end
end
