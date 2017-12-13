require 'dry/system/container'
require 'dry/system/stubs'

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

    describe '.require_from_root' do
      it 'requires a single file' do
        container.require_from_root(Pathname('lib/test/models'))

        expect(Test.const_defined?(:Models)).to be(true)
      end

      it 'requires many files when glob pattern is passed' do
        container.require_from_root(Pathname('lib/test/models/*.rb'))

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
          require 'test/foo'
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

  describe '.init' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/lazytest').realpath
        end

        load_paths!('lib')
      end
    end

    it 'lazy-boot a given system' do
      container.init(:bar)

      expect(Test.const_defined?(:Bar)).to be(true)
      expect(container.key?('test.bar')).to be(false)
    end
  end

  describe '.start' do
    shared_examples_for 'a booted system' do
      it 'boots a given system and finalizes it' do
        container.start(:bar)

        expect(Test.const_defined?(:Bar)).to be(true)
        expect(container['test.bar']).to eql('I was finalized')
      end

      it 'expects identifier to point to an existing boot file' do
        expect {
          container.start(:foo)
        }.to raise_error(
          ArgumentError,
          'component identifier +foo+ is invalid or boot file is missing'
        )
      end

      describe "mismatch betwenn finalize name and registered component" do
        it "raises a meaningful error" do
          expect{
            container.start(:hell)
          }.to raise_error(Dry::System::InvalidComponentIdentifierError)
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
  end

  describe '.stub' do
    let(:stubbed_car) do
      instance_double(Test::Car, wheels_count: 5)
    end

    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/stubbing').realpath
        end

        load_paths!('lib')
        auto_register!('lib')
      end
    end

    describe 'with stubs disabled' do
      it 'raises error when trying to stub frozen container' do
        expect { container.stub('test.car', stubbed_car) }.to raise_error(NoMethodError, /stub/)
      end
    end

    describe 'with stubs enabled' do
      before do
        container.enable_stubs!
      end

      it 'lazy-loads a component' do
        expect(container[:db]).to be_instance_of(Test::DB)
        container.finalize!
        expect(container[:db]).to be_instance_of(Test::DB)
      end

      it 'allows to stub components' do
        container.finalize!

        expect(container['test.car'].wheels_count).to be(4)

        container.stub('test.car', stubbed_car)

        expect(container['test.car'].wheels_count).to be(5)
      end
    end
  end
end
