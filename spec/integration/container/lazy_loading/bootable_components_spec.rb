# frozen_string_literal: true

RSpec.describe "Lazy loading bootable components" do
  describe "Booting component when resolving another components with bootable component as root key" do
    before do
      module Test
        class Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join("fixtures/lazy_loading/shared_root_keys").realpath
            config.component_dirs.add "lib"
          end
        end
      end
    end

    context "Single container" do
      it "boots the component and can resolve multiple other components registered using the same root key" do
        expect(Test::Container["kitten_service.fetch_kitten"]).to be
        expect(Test::Container.keys).to include("kitten_service.client", "kitten_service.fetch_kitten")
        expect(Test::Container["kitten_service.submit_kitten"]).to be
        expect(Test::Container.keys).to include("kitten_service.client", "kitten_service.fetch_kitten", "kitten_service.submit_kitten")
      end
    end

    context "Bootable component in imported container" do
      before do
        module Test
          class AnotherContainer < Dry::System::Container
            import from: Container, as: :core
          end
        end
      end

      context "lazy loading" do
        it "boots the component and can resolve multiple other components registered using the same root key" do
          expect(Test::AnotherContainer["core.kitten_service.fetch_kitten"]).to be
          expect(Test::AnotherContainer.keys).to include("core.kitten_service.fetch_kitten")

          expect(Test::AnotherContainer["core.kitten_service.submit_kitten"]).to be
          expect(Test::AnotherContainer.keys).to include("core.kitten_service.submit_kitten")

          expect(Test::AnotherContainer["core.kitten_service.client"]).to be
          expect(Test::AnotherContainer.keys).to include("core.kitten_service.client")
        end
      end

      context "finalized" do
        before do
          Test::AnotherContainer.finalize!
        end

        it "boots the component in the imported container and imports the bootable component's registered components" do
          expect(Test::AnotherContainer.keys).to include("core.kitten_service.fetch_kitten", "core.kitten_service.submit_kitten", "core.kitten_service.client")
        end
      end
    end
  end
end
