require 'ostruct'

RSpec.describe Dry::System::Container, '.boot' do
  subject(:system) { Test::Container }

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

  context 'inline booting' do
    before do
      class Test::Container < Dry::System::Container
      end
    end

    it 'allows setting up configuration and lifycycle steps' do
      system.boot(:db) do
        configure do |config|
          config.host = 'localhost'
          config.user = 'root'
          config.pass = 'secret'
          config.database = 'test'
          config.scheme = 'postgresql'
        end

        init do
          module Test
            class Db < OpenStruct
            end
          end
        end

        start do
          register(:conn, Test::Db.new(config.to_hash))
        end
      end

      system.start(:db)

      conn = system[:conn]

      expect(conn).to be_instance_of(Test::Db)

      expect(conn.host).to eql('localhost')
      expect(conn.user).to eql('root')
      expect(conn.pass).to eql('secret')
      expect(conn.database).to eql('test')
      expect(conn.scheme).to eql('postgresql')
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
      end

      conn = system['db.conn']

      expect(conn).to be_established
    end
  end
end
