RSpec.describe 'Registrations' do
  let(:container) { Test::Container }
  let(:another) { Test::AnotherContainer }

  before do
    require_relative '../fixtures/bacon/bacon'
    load(Pathname.new(__dir__).join('../container.rb'))
  end

  context 'pre-finalization' do
    describe 'manual registrations' do
      it 'loads matching missing key from container/strategies' do
        container['strategies.loose']
        expect(container.keys).to eq(%w{strategies.loose strategies.strict})
      end
    end

    describe 'automatic registrations' do
      it 'loads matching missing key from app/test/database/users' do
        expect(container['database.users']).to be_a(Test::Database::Users)
      end
    end
  end
end
