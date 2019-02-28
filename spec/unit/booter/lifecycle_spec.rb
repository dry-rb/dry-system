RSpec.describe Dry::System::Booter::Lifecycle do
  StateError = Dry::System::Booter::Lifecycle::StateError

  subject(:lifecycle) { Dry::System::Booter::Lifecycle.new(provider.identifier, provider) }
  let(:container) { Dry::Container.new }
  let(:block_spy) { spy(:provider) }
  let(:provider) do
    spy = block_spy

    Dry::System::Provider.new(:a_provider, :a_system) do |app|
      provides :a_key, 'compound.key'

      settings { key :some_string, Types::String }
      configure { |config| config.some_string = 'chunky_bacon' }

      boot { spy.boot; register(:foobar, 'bazfoo') }
      init { spy.init }
      start { spy.start }
      stop { spy.stop }

      [:boot, :init, :start, :stop].each do |event|
        before(event) { spy.send("before_#{event}") }
        after(event) { spy.send("after_#{event}") }
      end
    end
  end

  before do
    provider.boot!(container)
  end

  describe '#registered?' do
    it 'is initially registered before any lifecycle transitions' do
      expect(lifecycle).to be_registered
    end
  end

  describe '#provides' do
    specify { expect(lifecycle.provides).to eq([:a_key, 'compound.key']) }
  end

  describe '#provide?' do
    specify { expect(lifecycle.provide?(:a_key)).to be(true) }
    specify { expect(lifecycle.provide?('a_key')).to be(true) }
    specify { expect(lifecycle.provide?('compound.key')).to be(true) }
    specify { expect(lifecycle.provide?([:compound, :key])).to be(true) }
  end

  describe 'block methods' do
    describe '#register' do
      before { lifecycle.boot }
      specify { expect(lifecycle.container[:foobar]).to eq('bazfoo') }
    end

    describe '#config' do
      before { lifecycle.boot }
      specify { expect(lifecycle.config.to_hash).to eq({some_string: 'chunky_bacon'}) }
    end
  end

  describe 'lifecycle methods' do
    describe '#boot' do
      before do
        lifecycle.boot
      end

      specify do
        [:before_boot, :boot, :after_boot].each do |event|
          expect(block_spy).to have_received(event)
        end
        expect(lifecycle).to be_booted
      end

      context 'when already booted' do
        specify { expect { lifecycle.boot }.to raise_error(StateError) }
        specify { expect(lifecycle.init).to be_inited }
        specify { expect { lifecycle.start }.to raise_error(StateError) }
        specify { expect { lifecycle.stop }.to raise_error(StateError) }
      end
    end

    describe '#init' do
      before do
        lifecycle.boot
        lifecycle.init
      end

      specify do
        [:before_init, :init, :after_init].each do |event|
          expect(block_spy).to have_received(event)
        end

        expect(lifecycle).to be_inited
      end

      context 'when already inited' do
        specify { expect { lifecycle.boot }.to raise_error(StateError) }
        specify { expect { lifecycle.init }.to raise_error(StateError) }
        specify { expect(lifecycle.start).to be_started }
        specify { expect { lifecycle.stop }.to raise_error(StateError) }
      end
    end

    describe '#start' do
      before do
        lifecycle.boot
        lifecycle.init
        lifecycle.start
      end

      specify do
        [:before_start, :start, :after_start].each do |event|
          expect(block_spy).to have_received(event)
        end

        expect(lifecycle).to be_started
      end

      context 'when already started' do
        specify { expect { lifecycle.boot }.to raise_error(StateError) }
        specify { expect { lifecycle.init }.to raise_error(StateError) }
        specify { expect { lifecycle.start }.to raise_error(StateError) }
        specify { expect(lifecycle.stop).to be_stopped }
      end
    end

    describe '#stop' do
      before do
        lifecycle.boot
        lifecycle.init
        lifecycle.start
        lifecycle.stop
      end

      specify do
        [:before_stop, :stop, :after_stop].each do |event|
          expect(block_spy).to have_received(event)
        end

        expect(lifecycle).to be_stopped
      end

      context 'when already started' do
        specify { expect { lifecycle.boot }.to raise_error(StateError) }
        specify { expect { lifecycle.init }.to raise_error(StateError) }
        specify { expect { lifecycle.stop }.to raise_error(StateError) }

        specify do
          expect(lifecycle.start).to be_started

          [:before_start, :start, :after_start].each do |event|
            expect(block_spy).to have_received(event).exactly(2).times
          end
        end
      end
    end
  end
end
