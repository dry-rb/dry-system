# frozen_string_literal: true

RSpec::Matchers.define :have_memoized_component do |key|
  match do |container|
    container[key].eql?(container[key])
  end
end

RSpec.describe "Auto-registration / Memoizing components" do
  describe "Memoizing all components in a component directory" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").realpath

          config.component_dirs.add "components" do |dir|
            dir.namespaces.add "test", key: nil
            dir.memoize = true
          end

          config.inflector = Dry::Inflector.new { |i| i.acronym("ABC") }
        end
      end
    end

    shared_examples "memoizing components" do
      it "memoizes the components" do
        expect(Test::Container["foo"]).to be Test::Container["foo"]
      end
    end

    context "Finalized container" do
      before do
        Test::Container.finalize!
      end

      include_examples "memoizing components"
    end

    context "Non-finalized container" do
      include_examples "memoizing components"
    end
  end

  describe "Memoizing specific components in a component directory with a memoize proc" do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures").realpath

          config.component_dirs.add "components" do |dir|
            dir.namespaces.add "test", key: nil
            dir.memoize = proc do |component|
              !component.key.match?(/bar/)
            end
          end

          config.inflector = Dry::Inflector.new { |i| i.acronym("ABC") }
        end
      end
    end

    shared_examples "memoizing components" do
      it "memoizes the components matching the memoize proc" do
        expect(Test::Container["foo"]).to be Test::Container["foo"]
        expect(Test::Container["bar"]).not_to be Test::Container["bar"]
        expect(Test::Container["bar.baz"]).not_to be Test::Container["bar.baz"]
      end
    end

    context "Finalized container" do
      before do
        Test::Container.finalize!
      end

      include_examples "memoizing components"
    end

    context "Non-finalized container" do
      include_examples "memoizing components"
    end
  end

  describe "Memoizing specific components via magic comments" do
    shared_examples "memoizing components based on magic comments" do
      it "memoizes components with memoize: true" do
        expect(Test::Container).to have_memoized_component "memoize_true_comment"
      end

      it "does not memoize components with memoize: false" do
        expect(Test::Container).not_to have_memoized_component "memoize_false_comment"
      end
    end

    context "No memoizing config for component_dir" do
      before do
        class Test::Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures").realpath
            config.component_dirs.add "memoize_magic_comments" do |dir|
              dir.namespaces.add "test", key: nil
            end
          end
        end
      end

      include_examples "memoizing components based on magic comments"

      it "does not memoize components without magic comments" do
        expect(Test::Container).not_to have_memoized_component "memoize_no_comment"
      end
    end

    context "Memoize config 'false' for component_dir" do
      before do
        class Test::Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures").realpath
            config.component_dirs.add "memoize_magic_comments" do |dir|
              dir.namespaces.add "test", key: nil
              dir.memoize = false
            end
          end
        end
      end

      include_examples "memoizing components based on magic comments"

      it "does not memoize components without magic comments" do
        expect(Test::Container).not_to have_memoized_component "memoize_no_comment"
      end
    end

    context "Memoize config 'true' for component_dir" do
      before do
        class Test::Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures").realpath
            config.component_dirs.add "memoize_magic_comments" do |dir|
              dir.namespaces.add "test", key: nil
              dir.memoize = true
            end
          end
        end
      end

      include_examples "memoizing components based on magic comments"

      it "memoizes components without magic comments" do
        expect(Test::Container).to have_memoized_component "memoize_no_comment"
      end
    end
  end
end
