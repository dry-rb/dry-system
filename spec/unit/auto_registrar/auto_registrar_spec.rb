require 'dry/system/container'

RSpec.describe Dry::System::AutoRegistrar::AutoRegistrar do
  before(:all) do
    $LOAD_PATH.unshift(Pathname.new(__dir__).join('fixtures/components').realpath.to_s)
    $LOAD_PATH.unshift(Pathname.new(__dir__).join('fixtures/namespaced_components').realpath.to_s)
    $LOAD_PATH.unshift(Pathname.new(__dir__).join('fixtures/multiple_namespaced_components').realpath.to_s)
  end

  let(:container) { Dry::Container.new }
  let(:root) { Pathname.new(__dir__).join('fixtures').realpath }
  let(:loader) { Dry::System::Loader }
  let(:default_namespace) { nil }

  subject(:auto_registrar) do
    Dry::System::AutoRegistrar::AutoRegistrar.new(container, root, loader: loader, default_namespace: default_namespace)
  end

  context 'with a standard loader' do
    context 'default behavior' do
      before do
        auto_registrar.call('components')
      end

      it { expect(container['foo']).to be_an_instance_of(Foo) }
      it { expect(container['bar']).to be_an_instance_of(Bar) }

      it "doesn't register files with inline option 'auto_register: false'" do
        expect(container.key?('no_register')).to eql false
      end
    end

    context 'with custom configuration block' do
      it 'exclude specific components' do
        auto_registrar.call('components') do |config|
          config.instance do |component|
            component.identifier
          end

          config.exclude do |component|
            component.path =~ /bar/
          end
        end

        expect(container['foo']).to eql(:foo)
        expect(container.key?('bar')).to eql false
        expect(container.key?('bar.baz')).to eql false
      end
    end

    describe 'auto registration options' do
      context 'with default registration options' do
        it "does not memoize results" do
          auto_registrar.call('components')

          expect(container['foo']).to be_an_instance_of(Foo)
          expect(container['foo']).not_to be(container['foo'])
        end
      end

      context 'with memoization enabled' do
        it "memoizes results" do
          auto_registrar.call('components') do |config|
            config.memoize = true
          end

          expect(container['foo']).to be_an_instance_of(Foo)
          expect(container['foo']).to be(container['foo'])
        end
      end

      context 'with memoization disabled' do
        it "does not memoize results" do
          auto_registrar.call('components') do |config|
            config.memoize = false
          end

          expect(container['foo']).to be_an_instance_of(Foo)
          expect(container['foo']).not_to be(container['foo'])
        end
      end
    end

    context 'with default namespace with files nested in directory of same name' do
      let(:default_namespace) { :namespaced }

      before do
        auto_registrar.call('namespaced_components')
      end

      specify { expect(container['bar']).to be_a(Namespaced::Bar) }
      specify { expect(container['foo']).to be_a(Namespaced::Foo) }
    end

    context 'with default namespace but files are not nested in directory of same name' do
      let(:default_namespace) { :namespaced }

      before do
        auto_registrar.call('components')
      end

      specify { expect(container['foo']).to be_an_instance_of(Foo) }
      specify { expect(container['bar']).to be_an_instance_of(Bar) }
      specify { expect(container['bar.baz']).to be_an_instance_of(Bar::Baz) }
    end

    context 'with a nested default namespace' do
      let(:default_namespace) { [:multiple, :level] }

      before do
        auto_registrar.call('multiple_namespaced_components')
      end

      specify { expect(container['baz']).to be_a(Multiple::Level::Baz) }
      specify { expect(container['foz']).to be_a(Multiple::Level::Foz) }
    end
  end

  context 'with a custom loader' do
    let(:loader) {
      Class.new(Dry::System::Loader) do
        def instance
          constant.respond_to?(:call) ? constant : constant.new(*args)
        end
      end
    }

    before do
      auto_registrar.call('components')
    end

    it { expect(container['foo']).to be_an_instance_of(Foo) }
    it { expect(container['bar']).to eq(Bar) }
    it { expect(container['bar'].call).to eq("Welcome to my Moe's Tavern!") }
    it { expect(container['bar.baz']).to be_an_instance_of(Bar::Baz) }
  end
end
