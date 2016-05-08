require 'dry/component/container'

RSpec.describe Dry::Component::Container do
  subject(:container) { Test::Container }

  context 'with default core dir' do
    before do
      class Test::Container < Dry::Component::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/test').realpath
        end

        load_paths!('lib')
      end

      module Test
        Import = Container.Inject
      end
    end

    describe '.require' do
      it 'requires a single file' do
        container.require(Pathname('lib/test/models'))

        expect(Test.const_defined?(:Models)).to be(true)
      end

      it 'requires many files when glob pattern is passed' do
        container.require(Pathname('lib/test/models/*.rb'))

        expect(Test::Models.const_defined?(:User)).to be(true)
        expect(Test::Models.const_defined?(:Book)).to be(true)
      end
    end

    describe '.load_component' do
      it 'loads and registers components from configured load paths' do
        container.load_component('test.foo')

        expect(Test.const_defined?(:Foo)).to be(true)
        expect(Test.const_defined?(:Dep)).to be(true)

        expect(Test::Foo.new.dep).to be_instance_of(Test::Dep)
      end
    end
  end

  describe '.boot' do
    before do
      class Test::Container < Dry::Component::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/lazytest').realpath
        end

        load_paths!('lib')
      end
    end

    it 'lazy-boot a given component' do
      container.boot(:bar)

      expect(Test.const_defined?(:Bar)).to be(true)
      expect(container.key?('test.bar')).to be(false)
    end
  end

  describe '.boot!' do
    shared_examples_for 'a booted component' do
      it 'boots a given component and finalizes it' do
        container.boot!(:bar)

        expect(Test.const_defined?(:Bar)).to be(true)
        expect(container['test.bar']).to eql('I was finalized')
      end

      it 'expects a symbol identifier matching file name' do
        expect {
          container.boot!('bar')
        }.to raise_error(ArgumentError, 'component identifier must be a symbol')
      end

      it 'expects identifier to point to an existing boot file' do
        expect {
          container.boot!(:foo)
        }.to raise_error(
          ArgumentError,
          'component identifier +foo+ is invalid or boot file is missing'
        )
      end
    end

    context 'with the default core dir' do
      it_behaves_like 'a booted component' do
        before do
          class Test::Container < Dry::Component::Container
            configure do |config|
              config.root = SPEC_ROOT.join('fixtures/test').realpath
            end

            load_paths!('lib')
          end
        end
      end
    end

    context 'with a custom core dir' do
      it_behaves_like 'a booted component' do
        before do
          class Test::Container < Dry::Component::Container
            configure do |config|
              config.root = SPEC_ROOT.join('fixtures/other').realpath
              config.core_dir = 'config'
            end

            load_paths!('lib')
          end
        end
      end
    end

    it 'passes container to the finalizer block' do
      class Test::Container < Dry::Component::Container
        configure { |c| c.env = :awesome }

        finalize(:foo) do |container|
          register(:w00t, container.config.env)
        end
      end

      Test::Container.finalizers[:foo].()

      expect(Test::Container[:w00t]).to be(:awesome)
    end
  end
end
