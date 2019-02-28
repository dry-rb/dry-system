require 'dry/system/container/base'
require 'dry/system/container/core_mixin'
require 'dry/system_plugins/logger'
require 'dry/system_plugins/env/plugin'

RSpec.describe Dry::SystemPlugins::Logger do
  let(:container) { Test::Container }
  let(:environment) { nil }
  let(:configure_block) { Proc.new {} }
  let(:plugin) { container.plugins[:logger] }

  before do
    class Test::Container < Dry::System::Base
      extend Dry::System::Core::Mixin

      use(Dry::SystemPlugins::Env::Plugin)
      use(Dry::SystemPlugins::Logger)
    end

    container.configure do |config|
      config.env = environment if environment
      config.root = Pathname.new(__dir__).join('fixtures').realpath
      configure_block.call(config)
    end

    container.finalize!
  end

  it 'is available via a reader method on the container' do
    expect(plugin.instance).to be_a(::Logger)
    expect(container.logger).to be(plugin.instance)
  end

  it 'is also registered on the container' do
    expect(container[:logger]).to be(container.logger)
  end

  it 'actually logs to the file' do
    container.logger.info "info message"

    expect(File.read(plugin.log_file)).to include("info message")
  end

  context 'with different environments' do
    let(:environment) { :production }

    it 'varies the log_level based on environment' do
      expect(container.logger.level).to eq(::Logger::ERROR)
    end
  end

  context 'overriding the logger_class' do
    let(:logger_subclass) { Class.new(::Logger) }
    let(:configure_block) do
      klass = logger_subclass
      ->(config) { config.logging.logger_class = klass }
    end

    specify do
      expect(container.logger).to be_a(logger_subclass)
    end
  end
end
