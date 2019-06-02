# frozen_string_literal: true

RSpec.describe 'Lazy loading bootable components' do
  describe 'Booting component when resolving another components with bootable component as root key' do
    before do
      module Test
        class Container < Dry::System::Container
          configure do |config|
            config.root = SPEC_ROOT.join('fixtures/lazy_loading/shared_root_keys').realpath
          end

          load_paths! 'lib'
        end
      end
    end

    context 'Single container' do
      it 'boots the component and can resolve multiple other components registered using the same root key' do
        expect(Test::Container["kitten_service.fetch_kitten"]).to be
        expect(Test::Container.keys).to include("kitten_service.client", "kitten_service.fetch_kitten")
        expect(Test::Container["kitten_service.submit_kitten"]).to be
        expect(Test::Container.keys).to include("kitten_service.client", "kitten_service.fetch_kitten", "kitten_service.submit_kitten")
      end
    end

    context 'Bootable component in imported container' do
      before do
        module Test
          class AnotherContainer < Dry::System::Container
            import core: Container
          end
        end
      end

      it 'boots the component and can resolve multiple other components registered using the same root key' do
        expect(Test::AnotherContainer["core.kitten_service.fetch_kitten"]).to be
        expect(Test::AnotherContainer.keys).to include("core.kitten_service.client", "core.kitten_service.fetch_kitten")
        expect(Test::AnotherContainer["core.kitten_service.submit_kitten"]).to be
        expect(Test::AnotherContainer.keys).to include("core.kitten_service.client", "core.kitten_service.fetch_kitten", "core.kitten_service.submit_kitten")
      end
    end
  end
end
