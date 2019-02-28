RSpec.describe 'Booting' do
  let(:container) { Test::Container }

  before do
    require_relative '../fixtures/bacon/bacon'
    load(Pathname.new(__dir__).join('../container.rb'))
  end

  context 'pre-finalization' do
    it 'should be a blank slate initially' do
      expect(container.keys).to be_empty
    end

    describe 'starting a provider' do
      shared_examples_for 'a started provider' do
        context 'local provider' do
          context 'with no dependencies' do
            specify do
              container.send(container_method, :logger)
              expect(container.keys).to eq(%w{logger})
            end
          end

          context 'with local dependency' do
            it 'starts the dependencies as well' do
              container.send(container_method, :weather)
              expect(container.keys).to eq(%w{settings weather})
            end
          end

          context 'with external dependency' do
            it 'starts the dependencies as well' do
              container.send(container_method, :notifications)
              expect(container.keys).to eq(%w{in_memory notifications})
            end
          end

          context 'using external unbooted dependency (`use bacon: :dep`)' do
            it 'starts the dependencies as well' do
              container.send(container_method, :local_service)
              expect(container.keys).to eq(%w{dep local_service})
            end
          end
        end

        context 'external provider' do
          context 'with no dependencies' do
            specify do
              container.send(container_method, :router)
              expect(container.keys).to eq(%w{router})
            end
          end

          context 'with local (to us) dependency' do
            it 'starts the dependencies as well' do
              container.send(container_method, :database)
              expect(container.keys).to eq(%w{logger database})
            end
          end

          context 'using external (to us) unbooted dependency (`use bacon: :dep`)' do
            it 'starts the dependencies as well' do
              container.send(container_method, :service)
              expect(container.keys).to eq(%w{dep service})
            end
          end
        end
      end

      context 'manually starting a provider' do
        let(:container_method) { :start }
        it_behaves_like 'a started provider'
      end

      context 'implicitly starting a provider' do
        let(:container_method) { :resolve }
        it_behaves_like 'a started provider'
      end
    end

    describe 'customizing a registered provider' do
      specify 'settings can be configured' do
        # bacon/providers/database.rb has a `settings` block
        # container/system/boot/database.rb has a `configure` block

        expect(container[:database].database_url).to eq('http://example.com')
      end

      specify 'hooks allow additional code to be run around events' do
        # container/system/boot/router.rb#before(:start) hook
        expect(container[:router].class.config.locale).to eq(:en_US)

        # container/system/boot/router.rb#after(:start) hook
        expect(container[:router].route(:hello_world)).to eq('Hello, world!')
      end
    end

    describe 'stop' do
      it 'can manually stop a booted provider' do
        container.start(:notifications)
        container.stop(:in_memory)

        # bacon/lib/bacon/in_memory_store.rb, not a Lifecycle
        expect(container[:in_memory]).to be_stopped
      end
    end

    describe 'shutdown!' do
      it 'stops started providers' do
        container.start(:notifications)
        container.shutdown!

        # bacon/lib/bacon/in_memory_store.rb, not a Lifecycle
        expect(container[:in_memory]).to be_stopped
      end
    end
  end
end
