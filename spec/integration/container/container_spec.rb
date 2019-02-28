require 'dry/system/container'
require 'dry/system/stubs'

RSpec.describe Dry::System::Container do
  subject(:container) { Test::Container }
  let(:other_container) { Dry::Container.new }

  before do
    other_container.register(:baz, Object.new)

    class Test::Container < Dry::System::Container
      Test::Import = injector

      configure do |config|
        config.default_namespace = :test
        config.root = Pathname.new(__dir__).join('fixtures').realpath
      end

      load_paths!('lib')

      boot(:database) do
        provides :database
        init { register(:database, 'I am a database') }
      end
    end

    Test::Container.import(other: other_container)
  end

  describe '.resolve' do
    context 'pre-finalized' do
      it 'matches a key that a provider says it will register' do
        expect(container.resolve(:database)).to eq('I am a database')
      end

      it 'matches a file in a configured load path' do
        expect(container.resolve(:foo)).to be_a(Test::Foo)
      end

      it 'matches the root key against an imported container' do
        expect(container['other.baz']).to be(other_container[:baz])
      end

      it 'matches a file in the manual registrations path' do
        expect(Test::Container['foo.special']).to be_a(Test::Foo)
        expect(Test::Container['foo.special'].name).to eq "special"
      end

      it 'raises if does not match an existing file or imported container' do
        expect {
          container.resolve(:missing)
        }.to raise_error(Dry::System::ComponentLoadError, /missing/)
      end
    end

    context 'root key matches a booted provider' do
      it 'starts the provider with that name so it can register its objects' do
        expect(container['database.users']).to be_a(Test::Database::Users)
        expect(container['database']).to eq('I am a database')
      end
    end
  end

  describe '.injector' do
    it 'does what it says on the tin' do
      container.register(:good_eating, "chunky bacon")

      klass = Class.new do
        include Test::Import[:good_eating]
      end

      container.register(:yum) { klass.new }

      expect(container[:yum].good_eating).to eq('chunky bacon')
    end
  end
end
