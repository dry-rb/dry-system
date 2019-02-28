RSpec.describe Dry::System::Provider do
  let(:container) { Dry::Container.new }
  let(:block_spy) { spy(:provider) }
  subject(:provider) do
    Dry::System::Provider.new(:a_provider, :a_system) do |app|
      use :foobar
      provides :a_key, 'compound.key'

      settings { key :some_string, Types::String }
      configure { |config| config.some_string = 'chunky_bacon' }

      boot {}
      init {}
      start {}
      stop {}

      [:boot, :init, :start, :stop].each do |event|
        before(event) { spy.send("before_#{event}") }
        after(event) { spy.send("after_#{event}") }
      end
    end
  end

  describe "#boot!" do
    it 'gets the passed context as the block param' do
      expect { |b1|
        expect { |b2|
          Dry::System::Provider.new(:identifier, :system_identifier, definition: b1, callbacks: b2).boot!(container)
        }.to yield_with_args(container)
      }.to yield_with_args(container)
    end
  end

  context 'initial state' do
    specify { expect(provider.callbacks_block).to be(nil) }

    specify '#new' do
      block = ->() {}
      new_instance = provider.new(callbacks: block)
      expect(new_instance.callbacks_block).to eq(block)
    end
  end

  context 'booted' do
    before do
      provider.boot!(container)
    end

    [:boot_block, :init_block, :start_block, :stop_block, :settings_block, :configure_block].each do |ivar|
      specify { expect(provider.send(ivar)).not_to be(nil) }
    end

    specify { expect(provider.dependencies).to eq([:foobar]) }
    specify { expect(provider.provides).to eq([[:a_key], [:compound, :key]]) }
    specify { expect(provider.triggers[:before].keys).to eq([:boot, :init, :start, :stop])}
    specify { expect(provider.triggers[:after].keys).to eq([:boot, :init, :start, :stop])}
  end
end
