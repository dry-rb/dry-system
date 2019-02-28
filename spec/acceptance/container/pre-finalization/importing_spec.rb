RSpec.describe 'Booting' do
  let(:container) { Test::Container }
  let(:another) { Test::AnotherContainer }

  before do
    require_relative '../fixtures/bacon/bacon'
    load(Pathname.new(__dir__).join('../container.rb'))
  end

  context 'pre-finalization' do
    context 'loading missing key from imported container' do
      specify 'both should be a blank slate initially' do
        expect(container.keys).to be_empty
        expect(another.keys).to be_empty
      end

      it 'imports a key from a booted provider' do
        expect(container['another.projections']).to be_a(Test::Another::Projections)
        expect(another.keys).to eq(%w{projections statistics})
      end

      it 'injects imported objects with their dependencies' do
        expect(container['another.projections'].statistics).to eq('external statistics')
        expect(another.keys).to eq(%w{projections statistics})
      end

      it 'merges the other container after successful lookup, not just the requested key' do
        # another.statistics was resolved on the other container, but was imported
        # with the rest of the other container

        container['another.projections']
        expect(container.keys).to eq(%w{another.projections another.statistics})
      end

      demonstrate 'resolves auto-injected keys on the imported container even if overridden in our main container' do
        # This follows from the fact that the auto-injection is just vanilla Dry::AutoInject,
        # with the mixin included in Another::Projections coming from Test::AnotherContainer

        container.register(:statistics, 'our statistics')
        expect(container['another.projections'].statistics).to eq('external statistics')
      end
    end
  end
end
