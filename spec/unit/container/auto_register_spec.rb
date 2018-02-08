require 'dry/system/container'

RSpec.describe Dry::System::Container, '.auto_register!' do
  context 'standard loader' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures').realpath
        end

        load_paths!('components')
        auto_register!('components')
      end
    end

    it { expect(Test::Container['foo']).to be_an_instance_of(Foo) }
    it { expect(Test::Container['bar']).to be_an_instance_of(Bar) }
    it { expect(Test::Container['bar.baz']).to be_an_instance_of(Bar::Baz) }

    it "doesn't register files with inline option 'auto_register: false'" do
      expect(Test::Container.key?('no_register')).to eql false
    end
  end

  context 'with custom configuration block' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures').realpath
        end

        load_paths!('components')
      end
    end

    it 'exclude specific components' do
      Test::Container.auto_register!('components') do |config|
        config.instance do |component|
          component.identifier
        end

        config.exclude do |component|
          component.path =~ /bar/
        end
      end

      expect(Test::Container['foo']).to eql('foo')

      expect(Test::Container.key?('bar')).to eql false
      expect(Test::Container.key?('bar.baz')).to eql false
    end
  end

  context 'standard loader with a default namespace configured' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures').realpath
          config.default_namespace = 'namespaced'
        end

        load_paths!('namespaced_components')
        auto_register!('namespaced_components')
      end
    end

    specify { expect(Test::Container['bar']).to be_a(Namespaced::Bar) }
    specify { expect(Test::Container['bar'].foo).to be_a(Namespaced::Foo) }
    specify { expect(Test::Container['foo']).to be_a(Namespaced::Foo) }
  end

  context 'standard loader with a default namespace with multiple level' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures').realpath
          config.default_namespace = 'multiple.level'
        end

        load_paths!('multiple_namespaced_components')
        auto_register!('multiple_namespaced_components')
      end
    end

    specify { expect(Test::Container['baz']).to be_a(Multiple::Level::Baz) }
    specify { expect(Test::Container['foz']).to be_a(Multiple::Level::Foz) }
  end

  context 'with a custom loader' do
    before do
      class Test::Loader < Dry::System::Loader
        def call(*args)
          constant.respond_to?(:call) ? constant : constant.new(*args)
        end
      end

      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures').realpath
          config.loader = ::Test::Loader
        end

        load_paths!('components')
        auto_register!('components')
      end
    end

    it { expect(Test::Container['foo']).to be_an_instance_of(Foo) }
    it { expect(Test::Container['bar']).to eq(Bar) }
    it { expect(Test::Container['bar'].call).to eq("Welcome to my Moe's Tavern!") }
    it { expect(Test::Container['bar.baz']).to be_an_instance_of(Bar::Baz) }
  end
end
