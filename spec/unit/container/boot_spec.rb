# frozen_string_literal: true

RSpec.describe Dry::System::Container, ".register_provider" do
  subject(:system) { Test::App }

  let(:db) { spy(:db) }
  let(:client) { spy(:client) }

  before do
    Test.const_set(:DB, db)
    Test.const_set(:Client, client)

    module Test
      class App < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join("fixtures/test")
        end

        register_provider(:db) do
          prepare do
            register(:db, Test::DB)
            db.establish_connection
          end

          start do
            db.load
          end

          stop do
            db.close_connection
          end
        end

        register_provider(:client) do
          prepare do
            register(:client, Test::Client)
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

  describe "#init" do
    it "calls init function" do
      system.providers.prepare(:db)
      expect(db).to have_received(:establish_connection)
    end
  end

  describe "#start" do
    it "calls start function" do
      system.providers.start(:db)
      expect(db).to have_received(:load)
    end

    xit "store booted component" do
      system.providers.start(:db)
      expect(system.providers.booted.map(&:name)).to include(:db)
    end
  end

  describe "#stop" do
    context "provider has started" do
      it "calls stop function" do
        system.providers.start(:db)
        system.providers.stop(:db)
        expect(db).to have_received(:close_connection)
      end

      it "marks the provider as stopped" do
        expect {
          system.providers.start(:db)
          system.providers.stop(:db)
        }
          .to change { system.providers[:db].stopped? }
          .from(false). to true
      end
    end

    context "provider has not started" do
      it "does not call stop function" do
        system.providers.stop(:db)
        expect(db).not_to have_received(:close_connection)
      end

      it "does not mark the provider as stopped" do
        expect { system.providers.stop(:db) }.not_to change { system.providers[:db].stopped? }
        expect(system.providers[:db]).not_to be_stopped
      end
    end
  end

  describe "#shutdown" do
    it "calls stop function for every component" do
      system.providers.start(:db)
      system.providers.start(:client)
      system.providers.shutdown

      expect(db).to have_received(:close_connection)
      expect(client).to have_received(:close_connection)
    end
  end

  specify "boot triggers prepare" do
    system.providers.prepare(:db)

    expect(db).to have_received(:establish_connection)
    expect(db).to_not have_received(:load)
  end

  specify "start triggers init + start" do
    system.providers.start(:db)

    expect(db).to have_received(:establish_connection)
    expect(db).to have_received(:load)
  end

  specify "start raises error on undefined method or variable" do
    expect {
      system.register_provider(:broken_1) { oops("arg") }
      system.providers.start(:broken_1)
    }.to raise_error(NoMethodError, /oops/)

    expect {
      system.register_provider(:broken_2) { oops }
      system.providers.start(:broken_2)
    }.to raise_error(NameError, /oops/)
  end

  specify "lifecycle triggers are called only once" do
    system.providers.start(:db)
    system.providers.start(:db)

    system.providers.prepare(:db)
    system.providers.prepare(:db)

    expect(db).to have_received(:establish_connection).exactly(1)
    expect(db).to have_received(:load).exactly(1)

    expect(system.providers[:db].statuses).to eql(%i[prepare start])
  end

  it "raises when a duplicated identifier was used" do
    system.register_provider(:logger) {}

    expect {
      system.register_provider(:logger) {}
    }.to raise_error(Dry::System::ProviderAlreadyRegisteredError, /logger/)
  end

  it "allow setting namespace to true" do
    system.register_provider(:api, namespace: true) do
      start do
        register(:client, "connected")
      end
    end

    expect(system["api.client"]).to eql("connected")
  end

  it "raises when namespace value is not valid" do
    expect { system.register_provider(:api, namespace: 312) { } }
      .to raise_error(ArgumentError, /\+namespace:\+ must be true, string or symbol/)
  end
end
