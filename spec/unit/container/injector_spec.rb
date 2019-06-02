# frozen_string_literal: true

require 'dry/system/container'

RSpec.describe Dry::System::Container, '.injector' do
  context 'default injector' do
    it 'works correct' do
      Test::Foo = Class.new

      Test::Container = Class.new(Dry::System::Container) do
        register 'foo', Test::Foo.new
      end

      Test::Inject = Test::Container.injector

      injected_class = Class.new do
        include Test::Inject['foo']
      end

      obj = injected_class.new
      expect(obj.foo).to be_a Test::Foo

      another = Object.new
      obj = injected_class.new(foo: another)
      expect(obj.foo).to eq another
    end
  end

  context 'injector_options provided' do
    it 'builds an injector with the provided options' do
      Test::Foo = Class.new

      Test::Container = Class.new(Dry::System::Container) do
        register 'foo', Test::Foo.new
      end

      Test::Inject = Test::Container.injector(strategies: {
                                                default: Dry::AutoInject::Strategies::Args,
                                                australian: Dry::AutoInject::Strategies::Args
                                              })

      injected_class = Class.new do
        include Test::Inject.australian['foo']
      end

      obj = injected_class.new
      expect(obj.foo).to be_a Test::Foo

      another = Object.new
      obj = injected_class.new(another)
      expect(obj.foo).to eq another
    end
  end
end
