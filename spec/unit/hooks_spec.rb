RSpec.describe Dry::System::Hooks do
  subject(:hooks) { Dry::System::Hooks.new }
  let (:subscriber) { spy(:subscriber) }

  describe 'individual hooks' do
    it 'registers an after hook' do
      hooks.after(:configure) {}

      expect(hooks.events[:configure][:after].size).to eq(1)
    end

    it 'registers a before hook' do
      hooks.before(:configure) {}

      expect(hooks.events[:configure][:before].size).to eq(1)
    end

    it 'triggers hooks' do
      calls = []
      hooks.after(:configure) { calls << :after_configure }
      hooks.before(:configure) { calls << :before_configure }

      hooks.trigger(:configure)
      expect(calls).to eq([:before_configure, :after_configure])

      calls = []

      hooks.trigger(:configure, :before)
      expect(calls).to eq([:before_configure])
    end
  end

  describe 'subscribers' do
    before { hooks.subscribe(subscriber) }

    it 'register a subscriber' do
      expect(hooks.subscribers).to eq([subscriber])
    end

    it 'calls trigger on a subscriber' do
      allow(subscriber).to receive(:respond_to?).with("trigger_after_configure").and_return(false)
      expect(subscriber).to receive(:trigger).with(:configure, :after)
      hooks.trigger(:configure, :after)
    end

    it 'calls specific trigger handler on a subscriber' do
      expect(subscriber).to receive(:trigger_after_configure)
      hooks.trigger(:configure, :after)
    end
  end
end