require 'dry/system/container/core_mixin'
require 'dry/system/importer/plugin'
require 'dry/system/auto_registrar/plugin'

RSpec.describe Dry::System::Importer::Plugin do
  let(:other_container) do
    Dry::Container.new.tap do |container|
      container.register(:baz, Object.new)
    end
  end

  before do
    class Test::Container < Dry::System::Base
      extend Dry::System::Core::Mixin
      use(Dry::System::Importer::Plugin)

      configure {}
    end

    Test::Container.import(other: other_container)
  end

  let (:container) { Test::Container }
  subject(:importer) { container.importer }

  describe '#key_missing' do
    it 'auto-imports the other container' do
      expect(container['other.baz']).to be(other_container[:baz])
    end
  end
end
