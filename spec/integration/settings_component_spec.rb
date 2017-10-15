require 'dry/system/components'

RSpec.describe 'Settings component' do
  subject(:system) do
    Class.new(Dry::System::Container) do
      setting :env

      configure do |config|
        config.root = SPEC_ROOT.join('fixtures').join('settings_test')
        config.env = :test
      end

      boot(:settings, from: :system_components) do
        settings do
          key :database_url, type(String).constrained(filled: true)
          key :session_secret, type(String).constrained(filled: true)
        end
      end
    end
  end

  let(:settings) do
    system[:settings]
  end

  before do
    ENV['DATABASE_URL'] = 'sqlite::memory'
  end

  after do
    ENV.delete('DATABASE_URL')
  end

  it 'sets up system settings component via ENV and .env' do
    expect(settings.database_url).to eql('sqlite::memory')
    expect(settings.session_secret).to eql('super-secret')
  end
end
