require 'dry/system/plugins/plugin'
require 'dry/system/plugins/manager'
require 'dry/system/plugins/mixin'

RSpec.describe Dry::System::Plugins::Mixin do
  let(:plugin_class_spy) { spy(:plugin_class) }

  before do
    allow(plugin_class_spy).to receive(:config).and_return(OpenStruct.new(identifier: :foo, reader: true))
  end

  describe 'mixin' do
    subject(:target) do
      Class.new do
        extend Dry::System::Plugins::Mixin
      end
    end


  end
end
