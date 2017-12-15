RSpec.describe Dry::System::Container, '.use' do
  subject(:system) do
    Class.new(Dry::System::Container)
  end

  after do
    Dry::System::Plugins.registry.delete(:test_plugin)
  end

  context 'with a stateless plugin' do
    let(:plugin) do
      Module.new do
        def plugin_enabled?
          true
        end
      end
    end

    context 'plugin without a block' do
      before do
        Dry::System::Plugins.register(:test_plugin, plugin)
      end

      it 'enables a plugin' do
        system.use(:test_plugin)
        expect(system).to be_plugin_enabled
      end
    end

    context 'plugin with a block' do
      before do
        Dry::System::Plugins.register(:test_plugin, plugin) do
          setting :foo, "bar"
        end
      end

      it 'enables a plugin which evaluates its block' do
        system.use(:test_plugin)
        expect(system).to be_plugin_enabled
        expect(system.config.foo).to eql("bar")
      end
    end

    context 'inheritance' do
      before do
        Dry::System::Plugins.register(:test_plugin, plugin) do
          setting(:trace, [], &:dup)

          after(:configure) do
            config.trace << :works
          end
        end
      end

      it 'enables plugin for a class and its descendant' do
        system.use(:test_plugin)

        descendant = Class.new(system)

        system.configure {}
        descendant.configure {}

        expect(system.config.trace).to eql([:works])
        expect(descendant.config.trace).to eql([:works])
      end
    end

    context 'calling multiple times' do
      before do
        Dry::System::Plugins.register(:test_plugin, plugin) do
          setting :trace, []

          after(:configure) do
            config.trace << :works
          end
        end
      end

      it 'enables the plugin only once' do
        system.use(:test_plugin).use(:test_plugin).configure {}

        expect(system.config.trace).to eql([:works])
      end
    end
  end

  context 'with a stateful plugin' do
    let(:plugin) do
      Class.new(Module) do
        def initialize(options)
          @options = options

          define_method(:plugin_test) do
            options[:value]
          end
        end
      end
    end

    before do
      Dry::System::Plugins.register(:test_plugin, plugin)
    end

    it 'enables a plugin' do
      system.use(:test_plugin, value: "bar")
      expect(system.plugin_test).to eql("bar")
    end
  end
end
