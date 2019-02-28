require 'dry/system/container/core_mixin'
require 'dry/system/booter/plugin'
require 'dry/system/mixin'

RSpec.describe Dry::System::Booter::Plugin, '.finalize!' do
  before do
    module Test::Framework
      extend Dry::System::Mixin

      config.identifier = 'framework'
    end

    Test::Framework.register_provider(:router) do
      init { register(:router, 'I am a router') }
    end

    class Test::Container < Dry::System::Base
      extend Dry::System::Core::Mixin
      use(Dry::System::Booter::Plugin)

      configure do |config|
        config.root = Pathname.new(__dir__).join('fixtures').realpath
      end

      boot(:router, from: :framework)

      finalize!
    end
  end

  let(:container) { Test::Container }
  let(:booter) { container.booter }

  it 'auto-boots local providers from system/boot on finalize' do
    expect(booter[:database]).to be_started
    expect(container[:database]).to eq('I am a database')
  end

  it 'auto-starts providers on finalize' do
    expect(booter[:router]).to be_started
  end
end

