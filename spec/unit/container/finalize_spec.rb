RSpec.describe Dry::System::Container, '.finalize' do
  subject(:system) { Test::App }

  let(:db) { spy(:db) }

  before do
    Test.const_set(:DB, db)

    module Test
      class App < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures/test')
        end

        finalize(:db) do
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
  end

  describe '#stop' do
    it 'calls stop function' do
      system.booter.(:db).stop
      expect(db).to have_received(:close_connection)
    end
  end

  specify 'boot triggers init' do
    system.booter.boot(:db)

    expect(db).to have_received(:establish_connection)
    expect(db).to_not have_received(:load)
  end

  specify 'boot! triggers init + start' do
    system.booter.boot!(:db)

    expect(db).to have_received(:establish_connection)
    expect(db).to have_received(:load)
  end

  specify 'booter returns cached lifecycle objects' do
    expect(system.booter.(:db)).to be(system.booter.(:db))
  end

  specify 'lifecycle triggers are called only once' do
    system.booter.boot!(:db)
    system.booter.boot!(:db)

    system.booter.boot(:db)
    system.booter.boot(:db)

    expect(db).to have_received(:establish_connection).exactly(1)
    expect(db).to have_received(:load).exactly(1)

    expect(system.booter.(:db).statuses).to eql(%i[init start])
  end
end
