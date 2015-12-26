require 'dry/component/container'

RSpec.describe Dry::Component::Container, '.import' do
  subject(:app) { Class.new(Dry::Component::Container) }

  let(:db) do
    Class.new(Dry::Component::Container) do
      register(:users, %w(jane joe))
    end
  end

  shared_examples_for 'an extended container' do
    it 'imports one container into another' do
      expect(app.key?('persistence.users')).to be(false)

      app.finalize!

      expect(app['persistence.users']).to eql(%w(jane joe))
    end
  end

  context 'when a container has a name' do
    before do
      db.configure { |c| c.name = :persistence }
      app.import(db)
    end

    it_behaves_like 'an extended container'
  end

  context 'when container does not have a name' do
    before do
      app.import(persistence: db)
    end

    it_behaves_like 'an extended container'
  end
end
