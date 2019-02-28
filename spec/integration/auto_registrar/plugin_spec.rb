require 'dry/system/container/core_mixin'
require 'dry/system/auto_registrar/plugin'

RSpec.describe Dry::System::AutoRegistrar do
  before do
    class Test::Container < Dry::System::Base
      extend Dry::System::Core::Mixin
      use(Dry::System::AutoRegistrar::Plugin)

      configure do |config|
        config.default_namespace = :test
        config.auto_register = ['lib']
        config.root = Pathname.new(__dir__).join('fixtures').realpath
        load_paths!('lib')
      end
    end
  end

  let (:container) { Test::Container }
  subject(:auto_registrar) { container.auto_registrar }

  it 'is available via #auto_registrar method' do
    expect(auto_registrar).to be_a(Dry::System::AutoRegistrar::AutoRegistrar)
  end

  describe '#key_missing' do
    context 'with a key that matches a file that can be auto_registered' do
      specify do
        expect(container[:foo]).to be_a(Test::Foo)
      end
    end
  end
end
