# frozen_string_literal: true

RSpec.describe "Component dir namespaces / Namespaces as component dir defaults" do
  let(:container) {
    root = @dir
    cont_config = defined?(container_config) ? container_config : -> * {}

    Class.new(Dry::System::Container) {
      configure do |config|
        config.root = root

        cont_config.(config)
      end
    }
  }

  let(:container_config) {
    -> config {
      config.component_dirs.add "lib"

      config.component_dirs.namespaces.add "top_level_const", const: nil
      config.component_dirs.namespaces.add "top_level_key", key: nil

      config.component_dirs.add "xyz"
    }
  }

  before :context do
    @dir = make_tmp_directory

    with_directory(@dir) do
      write "lib/top_level_const/top_level_lib_component.rb", <<~RUBY
        class TopLevelLibComponent
        end
      RUBY

      write "xyz/top_level_const/top_level_xyz_component.rb", <<~RUBY
        class TopLevelXyzComponent
        end
      RUBY

      write "lib/top_level_key/nested/lib_component.rb", <<~RUBY
        module TopLevelKey
          module Nested
            class LibComponent
            end
          end
        end
      RUBY

      write "xyz/top_level_key/nested/xyz_component.rb", <<~RUBY
        module TopLevelKey
          module Nested
            class XyzComponent
            end
          end
        end
      RUBY
    end
  end

  context "lazy loading" do
    it "resolves the components from multiple component dirs according to the default namespaces" do
      expect(container["top_level_const.top_level_lib_component"]).to be_an_instance_of TopLevelLibComponent
      expect(container["top_level_const.top_level_xyz_component"]).to be_an_instance_of TopLevelXyzComponent

      expect(container["nested.lib_component"]).to be_an_instance_of TopLevelKey::Nested::LibComponent
      expect(container["nested.xyz_component"]).to be_an_instance_of TopLevelKey::Nested::XyzComponent
    end
  end

  context "finalized" do
    before do
      container.finalize!
    end

    it "resolves the components from multiple component dirs according to the default namespaces" do
      expect(container["top_level_const.top_level_lib_component"]).to be_an_instance_of TopLevelLibComponent
      expect(container["top_level_const.top_level_xyz_component"]).to be_an_instance_of TopLevelXyzComponent

      expect(container["nested.lib_component"]).to be_an_instance_of TopLevelKey::Nested::LibComponent
      expect(container["nested.xyz_component"]).to be_an_instance_of TopLevelKey::Nested::XyzComponent
    end
  end
end
