require 'dry/component/container'

RSpec.describe Dry::Component::Container, '.import' do
  let(:app) do
    Class.new(Dry::Component::Container)
  end

  let(:db) do
    Class.new(Dry::Component::Container) do
      register(:users, %w(jane joe))
    end
  end

  it 'imports one container into another' do
    app.import(persistence: db)

    expect(app.key?('persistence.users')).to be(false)

    app.finalize!

    expect(app['persistence.users']).to eql(%w(jane joe))
  end
end
