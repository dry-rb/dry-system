require 'dry/system/container'

RSpec.describe Dry::System::Container do
  subject(:container) { Test::Container }

  context 'with default core dir' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/test').realpath
        end

        load_paths!('lib')
      end

      module Test
        Import = Container.injector
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

    describe '.require_component' do

      shared_examples_for 'requireable' do
        it 'requires component file' do
          component = container.component('test/foo')
          required = false
          container.require_component(component) do
            required = true
          end
          expect(required).to be(true)
        end
      end

      it_behaves_like 'requireable'

      context 'when already required' do
        before do
          Kernel.require('test/foo')
        end

        it_behaves_like 'requireable'
      end

      it 'raises when file does not exist' do
        component = container.component('test/missing')
        expect { container.require_component(component) }.to raise_error(
          Dry::System::FileNotFoundError, /test\.missing/
        )
      end

      it 'returns for already registered components' do
        component = container.component('test/foo')

        registrar = -> {
          container.register(component.identifier) { component.instance }
        }

        container.require_component(component, &registrar)

        required = false
        registrar = -> { required = true }
        container.require_component(component, &registrar)
        expect(required).to be(false)
      end
    end

    describe '.load_component' do
      it 'loads and registers systems from configured load paths' do
        container.load_component('test.foo')

        expect(Test::Foo.new.dep).to be_instance_of(Test::Dep)
      end

      it "raises an error if a system's file can't be found" do
        expect { container.load_component('test.missing') }.to raise_error(
          Dry::System::ComponentLoadError, /test\.missing/
        )
      end

      it "is a no op if a matching system is already registered" do
        container.register "test.no_matching_file", Object.new

        expect { container.load_component("test.no_matching_file") }.not_to raise_error
      end
    end
  end

  describe '.boot' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/lazytest').realpath
        end

        load_paths!('lib')
      end
    end

    it 'lazy-boot a given system' do
      container.boot(:bar)

      expect(Test.const_defined?(:Bar)).to be(true)
      expect(container.key?('test.bar')).to be(false)
    end
  end

  describe '.boot!' do
    shared_examples_for 'a booted system' do
      it 'boots a given system and finalizes it' do
        container.boot!(:bar)

        expect(Test.const_defined?(:Bar)).to be(true)
        expect(container['test.bar']).to eql('I was finalized')
      end

      it 'expects a symbol identifier matching file name' do
        expect {
          container.boot!('bar')
        }.to raise_error(ArgumentError, 'component identifier "bar" must be a symbol')
      end

      it 'expects identifier to point to an existing boot file' do
        expect {
          container.boot!(:foo)
        }.to raise_error(
          ArgumentError,
          'component identifier +foo+ is invalid or boot file is missing'
        )
      end

      describe "missmatch betwenn finalize name and registered component" do
        it "raises a meaningful error" do
          expect{
            container.boot!(:hell)
          }.to raise_error(Dry::System::ComponentFileMismatchError)
        end
      end
    end

    context 'with the default core dir' do
      it_behaves_like 'a booted system' do
        before do
          class Test::Container < Dry::System::Container
            configure do |config|
              config.root = SPEC_ROOT.join('fixtures/test').realpath
            end

            load_paths!('lib')
          end
        end
      end
    end

    context 'with a custom core dir' do
      it_behaves_like 'a booted system' do
        before do
          class Test::Container < Dry::System::Container
            configure do |config|
              config.root = SPEC_ROOT.join('fixtures/other').realpath
              config.system_dir = 'config'
            end

            load_paths!('lib')
          end
        end
      end
    end

    it 'passes container to the finalizer block' do
      class Test::Container < Dry::System::Container
        configure { |c| c.name = :awesome }

        finalize(:foo) do |container|
          register(:w00t, container.config.name)
        end
      end

      Test::Container.booter.(:foo)

      expect(Test::Container[:w00t]).to be(:awesome)
    end
  end

  context 'Allow to stub container' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/stubbing').realpath
        end
        load_paths!('lib')
        auto_register!('lib')
      end
    end


    describe 'without enable_stubs!' do
      before do
        container.finalize!
      end

      it 'raises error when trying to stub freeze container' do
        expect {
          allow(container).to receive(:[]).with('mock').and_return(true)
        }.to raise_error(RuntimeError, /frozen/)
      end
    end

    describe 'with enable_stubs!' do
      before do
        container.enable_stubs!
        container.finalize!
      end

      it 'allow to stub the container it self' do
        expect(container['mock']).to eq false
        allow(container).to receive(:[]).with('mock').and_return(true)
        expect(container['mock']).to eq true
      end

      it 'allow to stub components' do
        car = container['stubbing.car']
        expect(car.wheels_count).to eq 4
        allow(car).to receive(:wheels_count).and_return(5)
        expect(car.wheels_count).to eq 5
      end
    end
  end
end
