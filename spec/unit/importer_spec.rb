require 'dry/system/container'

RSpec.describe Dry::System::Importer::Importer do
  let(:container) { Dry::Container.new }
  subject(:importer) { Dry::System::Importer::Importer.new(container) }

  let(:db) do
    Dry::Container.new.tap do |container|
      container.register(:users, %w(jane joe))
    end
  end

  describe '#call' do
    it 'imports the other container' do
      expect(container.key?('persistence.users')).to be(false)

      importer.call(:persistence, db)

      expect(container['persistence.users']).to eql(%w(jane joe))
    end
  end

  describe '#finalize!' do
    it 'imports the other container' do
      importer.register(persistence: db)

      expect(container.key?('persistence.users')).to be(false)

      importer.finalize!

      expect(container['persistence.users']).to eql(%w(jane joe))
    end
  end
end
