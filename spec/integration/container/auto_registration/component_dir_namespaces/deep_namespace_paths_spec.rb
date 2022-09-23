# frozen_string_literal: true

RSpec.describe "Component dir namespaces / Deep namespace paths" do
  let(:container) {
    root = @dir
    dir_config = defined?(component_dir_config) ? component_dir_config : -> * {}

    Class.new(Dry::System::Container) {
      configure! do |config|
        config.root = root
        config.component_dirs.add("lib", &dir_config)
      end
    }
  }

  context "key namespace not given" do
    let(:component_dir_config) {
      -> dir {
        dir.namespaces.add "ns/nested", const: nil
      }
    }

    before :context do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "lib/ns/nested/component.rb", <<~RUBY
          class Component
          end
        RUBY
      end
    end

    context "lazy loading" do
      it "registers components using the key namespace separator ('.'), not the path separator used for the namespace path" do
        expect(container["ns.nested.component"]).to be_an_instance_of Component
      end
    end

    context "finalized" do
      before do
        container.finalize!
      end

      it "registers components using the key namespace separator ('.'), not the path separator used for the namespace path" do
        expect(container["ns.nested.component"]).to be_an_instance_of Component
      end
    end
  end
end
