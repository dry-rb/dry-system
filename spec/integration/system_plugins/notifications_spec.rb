require 'dry/system/container/base'
require 'dry/system/container/core_mixin'
require 'dry/system_plugins/notifications'

RSpec.describe Dry::SystemPlugins::Notifications do
  let(:container) { Test::Container }
  let(:plugin) { container.plugins[:notifications] }

  before do
    class Test::Container < Dry::System::Base
      extend Dry::System::Core::Mixin
      use(Dry::SystemPlugins::Notifications)

      configure do |config|
        config.root = Pathname.new(__dir__).join('fixtures').realpath
      end

      finalize!
    end
  end

  it 'registers itself on the container' do
    expect(plugin.instance).to be_a(Dry::Monitor::Notifications)
    expect(container[:notifications]).to be(plugin.instance)
  end

  it 'is also accessible as a reader on the container' do
    expect(container.notifications).to be(plugin.instance)
  end
end
