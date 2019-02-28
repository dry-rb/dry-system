require 'ostruct'
require 'dry/system/plugins/manager'

RSpec.describe Dry::System::Plugins::Manager do
  let(:plugin_class_spy) { spy(:plugin_class) }
  let(:plugin_spy) { spy(:plugin) }
  let(:target) { Struct.new(:plugins, :config).new(nil, {}) }
  let(:plugin_config) do
    {identifier: :foo, reader: true}
  end

  subject(:manager) do
    Dry::System::Plugins::Manager.new(target).tap do |manager|
      target.plugins = manager
    end
  end

  before do
    allow(plugin_class_spy).to receive(:config).and_return(OpenStruct.new(plugin_config))
  end

  describe '#use' do
    it 'registers the plugin class for later instantiation' do
      manager.use(plugin_class_spy)
      expect(manager).to have_key(:foo)
    end
  end

  describe '#start' do
    before do
      allow(plugin_class_spy).to receive(:new).and_return(plugin_spy)
      allow(plugin_spy).to receive(:instance).and_return(plugin_spy)
      manager.use(plugin_class_spy)
      manager.start!
    end

    it 'initializes the plugins' do
      expect(plugin_class_spy).to have_received(:new)
    end

    context 'with reader true' do
      it 'adds the reader method to the target' do
        expect(target.foo).to be(plugin_spy)
      end
    end

    context 'with some other reader method specified' do
      let(:plugin_config) do
        {identifier: :foo, reader: :chunky_bacon}
      end

      it 'adds the reader method to the target' do
        expect(target.chunky_bacon).to be(plugin_spy)
      end
    end

    context 'with reader false' do
      let(:plugin_config) do
        {identifier: :foo, reader: false}
      end

      it 'does not add a reader method to the target' do
        expect(target).not_to respond_to(:foo)
      end
    end
  end

  context 'started with plugin' do
    before do
      allow(plugin_class_spy).to receive(:new).and_return(plugin_spy)
      manager.use(plugin_class_spy)
      manager.start!
    end

    describe '#trigger_after_configure' do
      it 'special-cases after_configure to pass the config object' do
        expect(plugin_spy).to receive(:after_configure).with(target.config)
        manager.trigger_after_configure
      end
    end

    describe '#trigger' do
      it 'dispatches any random hook so long as the plugin responds to it' do
        expect(plugin_spy).to receive(:before_foobar)
        manager.trigger(:foobar, :before)
      end
    end
  end
end
