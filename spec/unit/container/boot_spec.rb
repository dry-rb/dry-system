RSpec.describe Dry::System::Container, '.boot' do
  subject(:system) { Test::App }

  let(:db) { spy(:db) }
  let(:client) { spy(:client) }

  before do
    Test.const_set(:DB, db)
    Test.const_set(:Client, client)

    module Test
      class App < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/test')
        end

        boot(:db) do
          register(:db, Test::DB)

          init do
            db.establish_connection
          end

          start do
            db.load
          end

          stop do
            db.close_connection
          end
        end

        boot(:client) do
          register(:client, Test::Client)

          init do
            client.establish_connection
          end

          start do
            client.load
          end

          stop do
            client.close_connection
          end
        end
      end
    end
  end

  describe '#init' do
    it 'calls init function' do
      system.booter.(:db).init
      expect(db).to have_received(:establish_connection)
    end
  end

  describe '#start' do
    it 'calls start function' do
      system.booter.(:db).start
      expect(db).to have_received(:load)
    end

    it 'store booted component' do
      system.booter.start(:db)
      expect(system.booter.booted.map(&:identifier)).to include(:db)
    end
  end

  describe '#stop' do
    it 'calls stop function' do
      system.booter.(:db).stop
      expect(db).to have_received(:close_connection)
    end

    it 'remove booted component' do
      system.booter.start(:db)
      expect(system.booter.booted).to_not be_empty

      system.booter.stop(:db)
      expect(system.booter.booted).to be_empty
    end
  end

  describe '#shutdown' do
    it 'calls stop function for every component' do
      system.booter.start(:db)
      system.booter.start(:client)
      system.booter.shutdown

      expect(db).to have_received(:close_connection)
      expect(client).to have_received(:close_connection)
    end
  end

  specify 'boot triggers init' do
    system.booter.init(:db)

    expect(db).to have_received(:establish_connection)
    expect(db).to_not have_received(:load)
  end

  specify 'start triggers init + start' do
    system.booter.start(:db)

    expect(db).to have_received(:establish_connection)
    expect(db).to have_received(:load)
  end

  specify 'start raises error on undefined method or variable' do
    expect {
      system.boot(:broken_1) { oops('arg') }
      system.booter.start(:broken_1)
    }.to raise_error(NoMethodError, /oops/)

    expect {
      system.boot(:broken_2) { oops }
      system.booter.start(:broken_2)
    }.to raise_error(NameError, /oops/)
  end

  specify 'booter returns cached lifecycle objects' do
    expect(system.booter.(:db)).to be(system.booter.(:db))
  end

  specify 'lifecycle triggers are called only once' do
    system.booter.start(:db)
    system.booter.start(:db)

    system.booter.init(:db)
    system.booter.init(:db)

    expect(db).to have_received(:establish_connection).exactly(1)
    expect(db).to have_received(:load).exactly(1)

    expect(system.booter.(:db).statuses).to eql(%i[init start])
  end

  it 'raises when a duplicated identifier was used' do
    system.boot(:logger) { }

    expect {
      system.boot(:logger) { }
    }.to raise_error(Dry::System::DuplicatedComponentKeyError, /logger/)
  end

  it 'allow setting namespace to true' do
    system.boot(:api, namespace: true) do
      start do
        register(:client, 'connected')
      end
    end

    expect(system['api.client']).to eql('connected')
  end

  it 'raises when namespace value is not valid' do
    system.boot(:api, namespace: 312) do
      start do
        register(:client, 'connected')
      end
    end

    expect { system['api.client'] }.
      to raise_error(RuntimeError, /\+namespace\+ boot option must be true, string or symbol/)
  end
end
