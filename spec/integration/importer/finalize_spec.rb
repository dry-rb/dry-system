require 'dry/system/container/core_mixin'
require 'dry/system/importer/plugin'
require 'dry/system/auto_registrar/plugin'

RSpec.describe Dry::System::Importer, '.finalize' do
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
    Test::Container.finalize!
  end

  let (:container) { Test::Container }
  subject(:importer) { container.importer }

  it 'is available via #importer method' do
    expect(importer).to be_a(Dry::System::Importer::Importer)
  end
end
