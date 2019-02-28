require 'dry/system/container/base'
require 'dry/system/container/core_mixin'
require 'dry/system_plugins/notifications'
require 'dry/system_plugins/monitoring/plugin'

RSpec.describe Dry::SystemPlugins::Monitoring do
  let(:container) { Test::Container }

  before do
    class Test::Target
      def self.name; "Test::Class_#{__id__}"; end
      def other; end
      def say(word, &block)
        block.call if block
        word
      end
    end

    class Test::Container < Dry::System::Base
      extend Dry::System::Core::Mixin

      use(Dry::SystemPlugins::Notifications)
      use(Dry::SystemPlugins::Monitoring::Plugin)

      configure do |config|
        config.root = Pathname.new(__dir__).join('fixtures').realpath
      end
    end

    container.register(:target, Test::Target.new)

    # Don't finalize
  end

  it 'monitors object public method calls' do
    captured = []

    container.monitor(:target) do |event|
      captured << [event.id, event[:target], event[:method], event[:args]]
    end

    target = container[:target]
    block_result = []
    block = proc { block_result << true }

    result = target.say("hi", &block)

    expect(block_result).to eql([true])
    expect(result).to eql("hi")

    expect(captured).to eql([[:monitoring, :target, :say, ["hi"]]])
  end

  it 'monitors specified object method calls' do
    captured = []

    container.monitor(:target, methods: [:say]) do |event|
      captured << [event.id, event[:target], event[:method], event[:args]]
    end

    target = container[:target]

    target.say("hi")
    target.other

    expect(captured).to eql([[:monitoring, :target, :say, ["hi"]]])
  end
end
