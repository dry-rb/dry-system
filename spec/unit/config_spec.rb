require 'dry/component/container'

RSpec.describe Dry::Component::Config do
  before do
    class Test::App < Dry::Component::Container
      configure do |config|
        config.root = SPEC_ROOT.join('fixtures/test').realpath
      end
    end
  end

  it 'loads config under component name' do
    expect(Test::App.options.foo).to eql('bar')
  end
end
