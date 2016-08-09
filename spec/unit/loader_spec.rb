require 'dry/system/loader'
require 'singleton'

RSpec.describe Dry::System::Loader do
  let(:loader) { Dry::System::Loader.new('test/bar') }

  context 'not singleton' do
    subject(:instance) { loader.call }

    before do
      module Test
        class Bar
        end
      end
    end

    it 'returns a new instance of the constant' do
      expect(instance).to be_instance_of(Test::Bar)
      expect(instance).not_to be(loader.call)
    end
  end

  context 'singleton' do
    subject(:instance) { loader.call }

    before do
      module Test
        class Bar
          include Singleton
        end
      end
    end

    it 'returns singleton instance' do
      expect(instance).to be(Test::Bar.instance)
    end
  end
end
