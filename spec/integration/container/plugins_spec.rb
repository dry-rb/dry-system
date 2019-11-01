# frozen_string_literal: true

RSpec.describe Dry::System::Container, '.use' do
  subject(:system) do
    Class.new(Dry::System::Container)
  end

  before do
    # Store globals
    Test::PluginRegistry = Dry::System::Plugins.registry.dup
    Test::LoadedDependencies = Dry::System::Plugins.loaded_dependencies.dup
  end

  after do
    # Restore globals
    Dry::System::Plugins.instance_eval do
      @registry = Test::PluginRegistry
      @loaded_dependencies = Test::LoadedDependencies
    end
  end

  context 'with a plugin which has dependencies' do
    let(:plugin) do
      Module.new do
        def self.dependencies
          SPEC_ROOT.join('fixtures/test/lib/test/dep')
        end
      end
    end

    before do
      Dry::System::Plugins.register(:test_plugin, plugin)
    end

    context 'when another plugin has the same dependency' do
      context 'and dependencies are defined with the same type' do
        before do
          Dry::System::Plugins.register(:test_plugin_2, plugin)
        end

        it 'loads plugin and does not duplicate loaded_dependencies' do
          system.use(:test_plugin)
          system.use(:test_plugin_2)

          expect(Object.const_defined?('Test::Dep')).to be(true)

          expect(
            Dry::System::Plugins.loaded_dependencies.count { |dep|
              dep == SPEC_ROOT.join('fixtures/test/lib/test/dep').to_s
            }
          ).to be(1)
        end
      end

      context 'and dependencies are not defined with the same type' do
        let(:plugin_2) do
          Module.new do
            def self.dependencies
              SPEC_ROOT.join('fixtures/test/lib/test/dep').to_s
            end
          end
        end

        before do
          Dry::System::Plugins.register(:test_plugin_2, plugin_2)
        end

        it 'loads plugin and does not duplicate loaded_dependencies' do
          system.use(:test_plugin)
          system.use(:test_plugin_2)

          expect(Object.const_defined?('Test::Dep')).to be(true)

          expect(
            Dry::System::Plugins.loaded_dependencies.count { |dep|
              dep == SPEC_ROOT.join('fixtures/test/lib/test/dep').to_s
            }
          ).to be(1)
        end
      end
    end

    context 'when dependency is available' do
      it 'auto-requires dependency' do
        system.use(:test_plugin)

        expect(Object.const_defined?('Test::Dep')).to be(true)
      end
    end

    context 'when dependency is not available' do
      let(:plugin) do
        Module.new do
          def self.dependencies
            'this-does-not-exist'
          end
        end
      end

      it 'raises exception' do
        msg =
          if RUBY_ENGINE == 'jruby'
            'dry-system plugin :test_plugin failed to load its dependencies: no such file to load -- this-does-not-exist'
          else
            'dry-system plugin :test_plugin failed to load its dependencies: cannot load such file -- this-does-not-exist'
          end

        expect { system.use(:test_plugin) }.to raise_error(Dry::System::PluginDependencyMissing, msg)
      end
    end
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
          setting :foo, 'bar'
        end
      end

      it 'enables a plugin which evaluates its block' do
        system.use(:test_plugin)
        expect(system).to be_plugin_enabled
        expect(system.config.foo).to eql('bar')
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
      system.use(:test_plugin, value: 'bar')
      expect(system.plugin_test).to eql('bar')
    end
  end
end
