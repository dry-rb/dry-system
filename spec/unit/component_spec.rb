require 'dry/system/component'

RSpec.describe Dry::System::Component do
  subject(:component) { Dry::System::Component.new(name, options) }

  let(:options) do
    { namespace_separator: namespace_separator, path_separator: path_separator }
  end

  let(:namespace_separator) { '.' }
  let(:path_separator) { '/' }

  context 'with default separators' do
    let(:name) { :foo }

    describe '#identifier' do
      it 'returns qualified identifier' do
        expect(component.identifier).to eql('foo')
      end
    end

    describe '#namespaces' do
      it 'returns namespace array' do
        expect(component.namespaces).to eql(%i[foo])
      end
    end

    describe '#root_key' do
      it 'returns component key' do
        expect(component.root_key).to be(:foo)
      end
    end

    describe '#instance' do
      it 'builds an instance' do
        class Foo; end
        expect(component.instance).to be_instance_of(Foo)
        Object.send(:remove_const, :Foo)
      end
    end
  end
end
