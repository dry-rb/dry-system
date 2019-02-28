require 'dry/inflector'
require 'dry/system/loader'
require 'singleton'

RSpec.describe Dry::System::Loader, '#call' do
  let(:inflector) { Dry::Inflector.new }
  let(:path) { '' }
  subject(:loader) { Dry::System::Loader.new(path, inflector: inflector) }

  shared_examples_for 'object loader' do
    context 'not singleton' do
      it 'returns a new instance of the constant' do
        expect(loader.instance).to be_a(constant)
        expect(loader.instance).not_to be(loader.instance)
      end
    end

    context 'singleton' do
      before { constant.send(:include, Singleton) }

      it 'returns singleton instance' do
        expect(loader.instance).to be(constant.instance)
      end
    end
  end

  context 'with a singular name' do
    let(:path) { 'test/bar' }
    let(:constant) { Test::Bar }

    before do
      module Test;class Bar;end;end
    end

    it_behaves_like 'object loader'
  end

  context 'with a plural name' do
    let(:path) { 'test/bars' }
    let(:constant) { Test::Bars }

    before do
      module Test;class Bars;end;end
    end

    it_behaves_like 'object loader'
  end

  context 'with a constructor accepting args' do
    let(:path) { 'test/bar' }
    let(:constant) { Test::Bar }

    before do
      module Test
        Bar = Struct.new(:one, :two)
      end
    end

    it 'passes args to the constructor' do
      instance = loader.instance(1, 2)

      expect(instance.one).to be(1)
      expect(instance.two).to be(2)
    end
  end

  context 'with a custom inflector' do
    let(:inflector) { Dry::Inflector.new { |i| i.acronym('API') } }
    let(:path) { 'test/api_bar' }
    let(:constant) { Test::APIBar }

    before do
      Test::APIBar = Class.new
    end

    it_behaves_like 'object loader'
  end
end
