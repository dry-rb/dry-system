require 'dry/system/container/core_mixin'
require 'dry/system/manual_registrar/plugin'

RSpec.describe Dry::System::ManualRegistrar do
  before do
    class Test::Container < Dry::System::Base
      extend Dry::System::Core::Mixin
      use(Dry::System::ManualRegistrar::Plugin)

      configure do |config|
        config.default_namespace = :test
        config.root = Pathname.new(__dir__).join('fixtures').realpath
      end
    end
  end

  let (:container) { Test::Container }
  subject(:manual_registrar) { container.manual_registrar }

  it 'is available via #manual_registrar method' do
    expect(manual_registrar).to be_a(Dry::System::ManualRegistrar::ManualRegistrar)
  end

  describe '#key_missing' do
    context 'with a key that matches a file that can be handled' do
      specify do
        expect(container['foo.special']).to be_a(Test::Foo)
        expect(container['foo.special'].name).to eq('special')
      end
    end
  end
end
