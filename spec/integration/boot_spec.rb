require 'ostruct'

RSpec.describe Dry::System::Container, '.boot' do
  subject(:system) { Test::Container }
  let(:setup_db) do
    system.boot(:db) do
      init do
        module Test
          class Db < OpenStruct
          end
        end
      end

      start do
        register('db.conn', Test::Db.new(established: true))
      end

      stop do |container|
        container['db.conn'].established = false
      end
    end
  end

  let(:setup_client) do
    system.boot(:client) do
      init do
        module Test
          class Client < OpenStruct
          end
        end
      end

      start do
        register('client.conn', Test::Client.new(connected: true))
      end

      stop do |container|
        container['client.conn'].connected = false
      end
    end
  end

  context 'with a boot file' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/test').realpath
        end
      end
    end

    it 'auto-boots dependency of a bootable component' do
      system.start(:client)

      expect(system[:client]).to be_a(Client)
      expect(system[:client].logger).to be_a(Logger)
    end
  end

  context 'using predefined settings for configuration' do
    before do
      class Test::Container < Dry::System::Container
      end
    end

    it 'uses defaults' do
      system.boot(:api) do
        settings do
          key :token, Types::String.default('xxx')
        end

        start do
          register(:client, OpenStruct.new(config.to_hash))
        end
      end

      system.start(:api)

      client = system[:client]

      expect(client.token).to eql('xxx')
    end
  end

  context 'inline booting' do
    before do
      class Test::Container < Dry::System::Container
      end
    end

    it 'allows lazy-booting' do
      system.boot(:db) do
        init do
          module Test
            class Db < OpenStruct
            end
          end
        end

        start do
          register('db.conn', Test::Db.new(established?: true))
        end

        stop do
          db.conn.established = false
        end
      end
      conn = system['db.conn']

      expect(conn).to be_established
    end

    it 'allows component to be stopped' do
      setup_db
      system.start(:db)

      conn = system['db.conn']
      system.stop(:db)

      expect(conn.established).to eq false
    end

    it 'raises an error when trying to stop a component that has not been started' do
      setup_db

      expect {
        system.stop(:db)
      }.to raise_error(Dry::System::ComponentNotStartedError)
    end

    describe '#shutdown!' do
      it 'allows container to stop all started components' do
        setup_db
        setup_client

        db = system['db.conn']
        client = system['client.conn']
        system.shutdown!

        expect(db.established).to eq false
        expect(client.connected).to eq false
      end

      it 'skips components that has not been started' do
        setup_db
        setup_client

        db = system['db.conn']
        system.shutdown!

        expect {
          system.shutdown!
        }.to_not raise_error

        expect(db.established).to eq false
      end
    end
  end
end
