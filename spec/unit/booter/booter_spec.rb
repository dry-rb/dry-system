RSpec.describe Dry::System::Booter::Booter do
  subject(:booter) { Dry::System::Booter::Booter.new(container, systems) }

  let(:container) { Dry::Container.new }
  let(:systems) { {} }
  let(:db_spy) { spy(:db) }
  let(:db_provider) do
    db = db_spy
    Dry::System::Provider.new(:db, :persistence) do |app|
      provides :db

      boot { register('db.boot', 'db.boot'); db.boot }
      init { register('db.init', 'db.init'); db.init }
      start { register('db.start', 'db.start'); db.start }
      stop { db.stop }
    end
  end

  let(:foo_provider) do
    Dry::System::Provider.new(:foo, :__local__) do
      boot { register(:foo, "foo") }
    end
  end

  let(:local_client_provider) do
    Dry::System::Provider.new(:client, context: container) do
      use(:db)
      init { register(:client, {}) }
    end.boot!(container)
  end

  let(:system_client_provider) do
    Dry::System::Provider.new(:client, context: container) do
      use(persistence: :db)
      init { register(:client, {}) }
    end.boot!(container)
  end

  describe 'with namespaced provider' do
    before do
      booter.register(foo_provider)
      booter.boot(:foo, namespace: :baz)
      booter.start(:foo)
    end

    it 'namespaces any keys registered on the container' do
      expect(container.key?('baz.foo')).to be(true)
    end
  end

  describe '[]' do
    it 'raises error for broken or unregistered providers' do
      expect {
        booter[:broken]
      }.to raise_error(Dry::System::InvalidComponentIdentifierError)
    end
  end

  describe '#register' do
    context 'new system' do
      it 'adds a provider to the system' do
        booter.register(db_provider)
        expect(booter.systems[:persistence]).to eq({db: db_provider})
      end
    end

    context 'existing system' do
      let(:systems) { {persistence: {foo: :foo}} }

      it 'adds a provider to the system' do
        booter.register(db_provider)
        expect(booter.systems[:persistence]).to eq({foo: :foo, db: db_provider})
      end

      it 'raises error on duplicate identifier' do
        expect {
          booter.register(Dry::System::Provider.new(:foo, :persistence))
        }.to raise_error(Dry::System::DuplicatedComponentKeyError)
      end
    end
  end

  describe '#boot' do
    before do
      booter.register(db_provider)
      booter.register(foo_provider)
    end

    context 'valid provider' do
      context 'valid identifier' do
        before do
          booter.boot(:db, from: :persistence)
        end

        it 'is registered on the booter' do
          expect(booter.key?(:db)).to be true
        end

        it 'is returns a lifecycle object' do
          expect(booter[:db]).to be_a(Dry::System::Booter::Lifecycle)
        end

        it 'boots the provider' do
          expect(booter[:db]).to be_booted
        end

        it 'sets the identifier on the lifecycle object' do
          expect(booter[:db].identifier).to eq(:db)
        end
      end

      context 'duplicate identifier' do
        it 'raises an error' do
          booter.boot(:db, key: :foo)

          expect {
            booter.boot(:db, from: :persistence)
          }.to raise_error(Dry::System::DuplicatedComponentKeyError)
        end
      end
    end

    context 'configuring a provider' do
      it 'is passed the container as the block param' do
        expect { |b| booter.boot(:db, from: :persistence, &b) }.to yield_with_args(container)
      end
    end
  end

  context 'with booted provider' do
    before do
      booter.register(db_provider)
      booter.boot(:db, from: :persistence)
    end

    specify '#provided_keys' do
      expect(booter.provided_keys).to eq([:db])
    end

    specify '#provide?' do
      expect(booter.provide?(:db)).to be(true)
    end

    specify '#provider_for' do
      expect(booter.provider_for(:db)).to be(:db)
    end
  end

  describe 'lifecycle methods' do
    before do
      booter.register(db_provider)
      booter.boot(:db, from: :persistence)
    end

    describe '#init' do
      before do
        booter.init(:db)
      end

      it 'is inited' do
        expect(booter[:db]).to be_inited
      end

      it 'merges registrations with the context container' do
        expect(container.key?('db.init')).to be(true)
      end
    end

    describe '#start' do
      before do
        booter.start(:db)
      end

      it 'is started' do
        expect(booter[:db]).to be_started
      end

      it 'implicitly inits' do
        expect(db_spy).to have_received(:init)
      end

      it 'merges registrations with the context container' do
        expect(container.key?('db.start')).to be(true)
      end
    end

    describe '#stop' do
      before do
        booter.start(:db)
        booter.stop(:db)
      end

      it 'is stopped' do
        expect(booter[:db]).to be_stopped
      end

      it 'can be restarted' do
        booter.start(:db)
        expect(booter[:db]).to be_started
      end
    end

    describe '#shutdown' do
      before do
        booter.start(:db)
        booter.shutdown
      end

      it 'calls stop function for every component' do
        expect(db_spy).to have_received(:stop)
        expect(booter[:db]).to be_stopped
      end
    end
  end

  describe 'dependencies' do
    context 'explicit boot identifier' do
      it 'starts the db provider first' do
        booter.register(db_provider)
        booter.register(local_client_provider)
        booter.boot(:db, from: :persistence)
        booter.boot(:client)
        booter.start(:client)

        expect(booter[:db]).to be_started
      end
    end

    context 'scoped by system identifier (use persistence: :db)' do
      context 'external provider not yet booted' do
        it 'boots the dependency if necessary before starting it' do
          booter.register(db_provider)
          booter.register(system_client_provider)
          booter.boot(:client)
          booter.start(:client)

          expect(booter[:db]).to be_started
        end
      end

      context 'external provided booted under a different identifier' do
        it 'starts the db provider first' do
          booter.register(db_provider)
          booter.register(system_client_provider)
          booter.boot(:different_name, key: :db, from: :persistence)
          booter.boot(:client)
          booter.start(:client)

          expect(booter[:different_name]).to be_started
        end
      end
    end
  end
end
