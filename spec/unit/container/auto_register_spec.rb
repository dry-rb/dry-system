require 'dry/component/container'

RSpec.describe Dry::Component::Container, '.auto_register!' do
  context 'with the standard loader' do
    before do
      class Test::Container < Dry::Component::Container
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
  end

  context 'with a custom loader' do
    before do
      class Test::Loader < Dry::Component::Loader
        def identifier
          super.gsub('.', '-')
        end

        def instance(*args)
          constant.respond_to?(:call) ? constant : constant.new(*args)
        end
      end

      class Test::Container < Dry::Component::Container
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
    it { expect(Test::Container['bar-baz']).to be_an_instance_of(Bar::Baz) }
  end
end
