require 'ostruct'
require 'dry/system/container/base'

RSpec.describe Dry::System::Base do
  subject(:container) { Test::Container }

  describe 'plugins' do
    let(:plugin_class) { spy(:plugin_class) }
    let(:plugin) { spy(:plugin) }

    before do
      allow(plugin_class).to receive(:config).and_return(OpenStruct.new({identifier: :foo}))
      Test::Container = Class.new(Dry::System::Base)
      Test::Container.use(plugin_class)
    end

    it 'makes plugins available' do
      expect(container.plugins).to be_a(Dry::System::Plugins::Manager)
    end

    it 'starts plugins before configure' do
      expect(plugin_class).to receive(:new).and_return(plugin)
      expect(plugin).to receive(:after_configure)
      container.configure
    end

    it 'inherits plugins' do
      container.use(plugin_class)
      subclass = Class.new(container)
      expect(subclass.plugins.key?(:foo)).to be(true)
      expect(subclass.plugins.container).to be(subclass)
    end

    describe '.use' do
      it 'registers a plugin on the class' do
        container.use(plugin_class)
        expect(container.plugins.key?(:foo)).to be(true)
      end
    end
  end

  describe '.finalize!' do
    before do
      Test::Container = Class.new(Dry::System::Base)
    end

    it 'calls finalize hook' do
      fun = false

      container.hooks.before(:finalize) do
        fun = true
      end

      container.finalize!

      expect(fun).to be true
    end

    it 'reports that it is finalized' do
      container.finalize!
      expect(container).to be_finalized
    end
  end
end
