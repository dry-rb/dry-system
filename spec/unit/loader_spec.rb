require 'dry/system/loader'
require 'singleton'

RSpec.describe Dry::System::Loader, '#call' do
  shared_examples_for 'object loader' do
    let(:instance) { loader.call }

    context 'not singleton' do
      it 'returns a new instance of the constant' do
        expect(instance).to be_instance_of(constant)
        expect(instance).not_to be(loader.call)
      end
    end

    context 'singleton' do
      before { constant.send(:include, Singleton) }

      it 'returns singleton instance' do
        expect(instance).to be(constant.instance)
      end
    end
  end

  context 'with a singular name' do
    subject(:loader) { Dry::System::Loader.new('test/bar') }

    let(:constant) { Test::Bar }

    before do
      module Test;class Bar;end;end
    end

    it_behaves_like 'object loader'
  end

  context 'with a plural name' do
    subject(:loader) { Dry::System::Loader.new('test/bars') }

    let(:constant) { Test::Bars }

    before do
      module Test;class Bars;end;end
    end

    it_behaves_like 'object loader'
  end
end
