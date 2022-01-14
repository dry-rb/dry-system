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

    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = root
        config.component_dirs.add "lib" do |dir|
          dir.namespaces.add_root const: "test"
        end
      end
    }
  }

  let(:importing_container) {
    exporting_container = self.exporting_container

    Class.new(Dry::System::Container) {
      import other: exporting_container
    }
  }

  context "exports configured" do
    before do
      # I wonder if this should be a class-level thing rather than config... that'd make
      # it symmetrical with `import`
      #
      # Another question to consider here is whether anything registering an
      # after_configure hook might want access to these
      exporting_container.config.exports = %w[
        exportable_component_a
        nested.exportable_component_b
      ]
    end

    it "imports only the components explicitly marked as exports" do
      expect(importing_container.key?("other.exportable_component_a")).to be true
      expect(importing_container.key?("other.nested.exportable_component_b")).to be true
      expect(importing_container.key?("other.private_component")).to be false
    end

    it "does not finalize the exporting container" do
      importing_container.importer.finalize!

      expect(exporting_container).not_to be_finalized
    end

    it "does not load components not marked for export" do
      importing_container.importer.finalize!

      expect(exporting_container.registered?("exportable_component_a")).to be true
      expect(exporting_container.registered?("private_component")).to be false
    end
  end

  context "empty exports configured" do
    before do
      exporting_container.config.exports = []
    end

    it "imports nothing" do
      expect(importing_container.key?("other.exportable_component_a")).to be false
      expect(importing_container.key?("other.nested.exportable_component_b")).to be false
      expect(importing_container.key?("other.private_component")).to be false
    end

    it "does not finalize the exporting container" do
      importing_container.importer.finalize!

      expect(exporting_container).not_to be_finalized
    end

    it "does not load any components in the exporting container" do
      expect(exporting_container.keys).to be_empty
    end
  end

  context "exports not configured" do
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
