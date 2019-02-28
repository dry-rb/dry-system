RSpec.describe 'Dry::AutoInject' do
  let(:container) { Test::Container }

  before do
    module Test
      Foo = Class.new
      Container = Class.new(Dry::System::Container)
      Inject = Container.injector(strategies: {
        default: Dry::AutoInject::Strategies::Args,
        australian: Dry::AutoInject::Strategies::Args
      })

      class Injected
        include Inject.australian["foo"]
      end
    end

    container.register(:foo, Test::Foo.new)
  end

  specify do
    not_injected = Object.new

    expect(Test::Injected.new.foo).to be_a(Test::Foo)
    expect(Test::Injected.new(not_injected).foo).to be(not_injected)
  end
end
