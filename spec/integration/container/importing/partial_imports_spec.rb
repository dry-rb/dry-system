# frozen_string_literal: true

RSpec.describe "Container / Imports / Partial imports" do
  before :context do
    @dir = make_tmp_directory

    with_directory @dir do
      write "lib/exportable_component_a.rb", <<~RUBY
        module Test
          class ExportableComponentA; end
        end
      RUBY

      write "lib/exportable_component_b.rb", <<~RUBY
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
    import_keys = self.import_keys

    Class.new(Dry::System::Container) {
      import keys: import_keys, from: exporting_container, as: :other
    }
  }

  let(:import_keys) { ["exportable_component_a"] }

  context "no exports configured (whole container export)" do
    context "lazy loading" do
      it "imports the specified components only" do
        expect(importing_container.key?("other.exportable_component_a")).to be true
        expect(importing_container.key?("other.exportable_component_b")).to be false
      end
    end

    context "finalized" do
      before do
        importing_container.finalize!
      end

      it "imports the specified components only" do
        expect(importing_container.key?("other.exportable_component_a")).to be true
        expect(importing_container.key?("other.exportable_component_b")).to be false
      end
    end
  end

  context "exports configured (with import keys included)" do
    let(:exports) { ["exportable_component_a", "exportable_component_b"] }

    context "lazy loading" do
      it "imports the specified components only" do
        expect(importing_container.key?("other.exportable_component_a")).to be true
        expect(importing_container.key?("other.exportable_component_b")).to be false
      end
    end

    context "finalized" do
      before do
        importing_container.finalize!
      end

      it "imports the specified components only" do
        expect(importing_container.key?("other.exportable_component_a")).to be true
        expect(importing_container.key?("other.exportable_component_b")).to be false
      end
    end
  end

  context "exports configured (with import keys not included)" do
    let(:exports) { ["exportable_component_b"] }

    context "lazy loading" do
      it "does not import any components" do
        expect(importing_container.key?("other.exportable_component_a")).to be false
      end
    end

    context "finalized" do
      before do
        importing_container.finalize!
      end

      it "does not import any components" do
        expect(importing_container.key?("other.exportable_component_a")).to be false
      end
    end
  end

  context "import keys specified that do not exist in exporting container" do
    let(:import_keys) { ["exportable_component_a", "non_existent_key"] }

    context "lazy loading" do
      it "imports the existent components only" do
        expect(importing_container.key?("other.exportable_component_a")).to be true
        expect(importing_container.key?("other.non_existent_key")).to be false
      end
    end

    context "finalized" do
      before do
        importing_container.finalize!
      end

      it "imports the existent components only" do
        expect(importing_container.key?("other.exportable_component_a")).to be true
        expect(importing_container.key?("other.non_existent_key")).to be false
      end
    end
  end
end
