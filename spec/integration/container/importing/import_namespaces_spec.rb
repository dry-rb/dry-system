# frozen_string_literal: true

RSpec.describe "Container / Imports / Import namespaces" do
  before :context do
    @dir = make_tmp_directory

    with_directory @dir do
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

  context "nil namespace" do
    context "no keys specified" do
      let(:importing_container) {
        exporting_container = self.exporting_container

        Class.new(Dry::System::Container) {
          import from: exporting_container, as: nil
        }
      }

      context "importing container is lazy loading" do
        it "imports all the components" do
          expect(importing_container.key?("exportable_component_a")).to be true
          expect(importing_container.key?("nested.exportable_component_b")).to be true
          expect(importing_container.key?("non_existent")).to be false
        end
      end

      context "importing container is finalized" do
        before do
          importing_container.finalize!
        end

        it "imports all the components" do
          expect(importing_container.key?("exportable_component_a")).to be true
          expect(importing_container.key?("nested.exportable_component_b")).to be true
          expect(importing_container.key?("non_existent")).to be false
        end
      end
    end

    context "keys specified" do
      let(:importing_container) {
        exporting_container = self.exporting_container

        Class.new(Dry::System::Container) {
          import keys: ["exportable_component_a"], from: exporting_container, as: nil
        }
      }

      context "importing container is lazy loading" do
        it "imports the specified components only" do
          expect(importing_container.key?("exportable_component_a")).to be true
          expect(importing_container.key?("nested.exportable_component_b")).to be false
        end
      end

      context "importing container is finalized" do
        before do
          importing_container.finalize!
        end

        it "imports the specified components only" do
          expect(importing_container.key?("exportable_component_a")).to be true
          expect(importing_container.key?("nested.exportable_component_b")).to be false
        end
      end
    end
  end
end
