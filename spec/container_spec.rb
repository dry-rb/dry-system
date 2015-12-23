RSpec.describe Rodakase::Container do
  before do
    module Test
      class Container < Rodakase::Container
        setting :root, SPEC_ROOT.join('fixtures/test').realpath

        configure do
          load_paths!('lib')
        end
      end
    end

    module Test
      Import = Container.import_module
    end
  end

  describe '.require' do
    it 'requires a single file' do
      Test::Container.require('lib/test/models')

      expect(Test.const_defined?(:Models)).to be(true)
    end

    it 'requires many files when glob pattern is passed' do
      Test::Container.require('lib/test/models/*.rb')

      expect(Test::Models.const_defined?(:User)).to be(true)
      expect(Test::Models.const_defined?(:Book)).to be(true)
    end
  end

  describe '.require_component' do
    it 'requires components from configured load paths' do
      Test::Container.require_component('test.foo')

      expect(Test.const_defined?(:Foo)).to be(true)
      expect(Test.const_defined?(:Dep)).to be(true)

      expect(Test::Foo.new.dep).to be_instance_of(Test::Dep)
    end
  end

  describe '.boot!' do
    it 'boots a given component and finalizes it' do
      Test::Container.boot!(:bar)

      expect(Test.const_defined?(:Bar)).to be(true)
      expect(Test::Container['test.bar']).to eql('I was finalized')
    end

    it 'expects a symbol identifier matching file name' do
      expect {
        Test::Container.boot!('bar')
      }.to raise_error(ArgumentError, 'component identifier must be a symbol')
    end

    it 'expects identifier to point to an existing boot file' do
      expect {
        Test::Container.boot!(:foo)
      }.to raise_error(ArgumentError, 'component identifier +foo+ is invalid or boot file is missing')
    end
  end
end
