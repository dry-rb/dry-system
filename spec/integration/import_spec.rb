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

      App.import(Umbrella)
      Import = App.injector
    end
  end

  let(:user_repo) do
    Class.new { include Test::Import['core.db.repo'] }.new
  end

  it 'lazy boots an external dep provided by top-level container' do
    expect(user_repo.repo).to be_instance_of(Db::Repo)
  end

  it 'loads an external dep during finalization' do
    Test::App.finalize!
    expect(user_repo.repo).to be_instance_of(Db::Repo)
  end
end
