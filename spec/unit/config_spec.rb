require 'dry/component/container'

RSpec.describe Dry::Component::Config do
  before do
    class Test::App < Dry::Component::Container
      configure do |config|
        config.name = :application
        config.root = SPEC_ROOT.join('fixtures/test').realpath
      end
    end

    class Test::SubApp < Dry::Component::Container
      configure do |config|
        config.name = :subapp
        config.root = SPEC_ROOT.join('fixtures/test').realpath
      end
    end
  end

  it 'loads config under component name' do
    expect(Test::App.options.foo).to eql('bar')
  end

  it 'allows different components to have different configurations' do
    expect(Test::SubApp.options.bar).to eql('baz')
  end

  it 'erb processes the config before passing to yaml' do
    expect(Test::App.options.env).not_to be_nil
  end
end
