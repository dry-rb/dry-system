RSpec.describe 'Lazy-booting external deps' do
  before do
    module Test
      class Umbrella < Dry::System::Container
        configure do |config|
          config.name = :core
          config.root = SPEC_ROOT.join('fixtures/umbrella').realpath
        end
      end

      class App < Dry::System::Container
        configure do |config|
          config.name = :main
        end
      end
    end
  end

  shared_examples_for 'lazy booted dependency' do
    it 'lazy boots an external dep provided by top-level container' do
      expect(user_repo.repo).to be_instance_of(Db::Repo)
    end

    it 'loads an external dep during finalization' do
      system.finalize!
      expect(user_repo.repo).to be_instance_of(Db::Repo)
    end
  end

  context 'when top-level container provides the dependency' do
    let(:user_repo) do
      Class.new { include Test::Import['db.repo'] }.new
    end

    let(:system) { Test::Umbrella }

    before do
      module Test
        Umbrella.import(main: App)
        Import = Umbrella.injector
      end
    end

    it_behaves_like 'lazy booted dependency'
  end

  context 'when top-level container provides the dependency through import' do
    let(:user_repo) do
      Class.new { include Test::Import['core.db.repo'] }.new
    end

    let(:system) { Test::App }

    before do
      module Test
        App.import(core: Umbrella)
        Import = App.injector
      end
    end

    it_behaves_like 'lazy booted dependency'
  end
end
