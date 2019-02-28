require 'dry/system/container/base'
require 'dry/system/container/core_mixin'
require 'dry/system_plugins/env/plugin'

RSpec.describe Dry::SystemPlugins::Env do
  let(:container) { Test::Container }
  let(:plugin) { Class.new(Dry::SystemPlugins::Env::Plugin) }
  let(:inferrer) { nil }
  let(:environment) { nil }

  before do
    plugin.config.inferrer = inferrer

    class Test::Container < Dry::System::Base
      extend Dry::System::Core::Mixin
    end

    container.use(plugin)

    container.configure do |config|
      config.env = environment if environment
      config.root = Pathname.new(__dir__).join('fixtures').realpath
    end

    container.finalize!
  end

  it 'defaults environment to development' do
    expect(container.config.env).to eq(:development)
  end

  it 'loads the env files and makes available as container.env' do
    expect(container.env).to be_a(Hash)
  end

  it 'combines the base env and specific environment files' do
    expect(container.env).to eq({'OVERRIDDEN_VALUE' => 'foobar', 'BASE_VALUE' => 'bar', 'DEVELOPMENT' => 'baz'})
  end

  context 'with specified environment' do
    let(:environment) { :production }

    it 'only includes values from specified environment' do
      expect(container.env).to eq({'OVERRIDDEN_VALUE' => 'foobaz', 'BASE_VALUE' => 'bar', 'PRODUCTION' => 'bazbar'})
    end
  end

  context 'with a custom inferrer' do
    let(:inferrer) { ->{ :test } }

    specify do
      expect(container.config.env).to eq(:test)
    end

    it 'still has base values if no specific file for current environment' do
      expect(container.env).to eq({'OVERRIDDEN_VALUE' => 'foo', 'BASE_VALUE' => 'bar'})
    end
  end
end
