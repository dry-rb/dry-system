require 'dry/system/container/core_mixin'
require 'dry/system/auto_registrar/plugin'

RSpec.describe Dry::System::AutoRegistrar, '.finalize' do
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

      finalize!
    end
  end

  let (:container) { Test::Container }
  subject(:auto_registrar) { container.auto_registrar }

  it 'auto-registers the lib directory' do
    expect(container[:bar]).to be_a(Test::Bar)
    expect(container['namespace.foobar']).to be_a(Test::Namespace::Foobar)
  end
end
