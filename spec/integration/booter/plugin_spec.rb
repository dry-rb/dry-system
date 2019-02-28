require 'dry/system/container/core_mixin'
require 'dry/system/booter/plugin'
require 'dry/system/mixin'

RSpec.describe Dry::System::Booter::Plugin do
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

      boot(:foo) do
        provides :foobar

        start do
          register(:foobar, :chunky_bacon)
        end
      end
    end
  end

  let(:container) { Test::Container }
  let(:plugin) { container.plugins[:booter] }
  subject(:booter) { container.booter }

  describe '#key_missing' do
    context 'with a provider that provides the key' do
      it 'starts the provider and returns true' do
        expect(container[:foobar]).to eq(:chunky_bacon)
        expect(booter[:foo]).to be_started
      end
    end
  end

  it 'auto-registers the framework system' do
    container.boot(:router, from: :framework)
    expect(booter[:router]).to be_booted
  end

  it 'requires local boot files' do
    expect(Test.const_defined?(:BootFile)).to be(true)
  end

  it 'can start a provider' do
    container.start(:foo)
    expect(booter[:foo]).to be_started
  end

  it 'can stop a provider' do
    container.start(:foo)
    container.stop(:foo)
    expect(booter[:foo]).to be_stopped
  end
end

