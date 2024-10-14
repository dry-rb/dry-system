# frozen_string_literal: true

RSpec.describe Dry::System::Container do
  subject(:system) do
    Class.new(described_class)
  end

  describe "after_register hook" do
    it "executes after a new key is registered" do
      expect { |hook|
        system.after(:register, &hook)
        system.register(:foo) { "bar" }
      }.to yield_with_args(:foo)
    end

    it "provides the fully-qualified key" do
      expect { |hook|
        system.after(:register, &hook)
        system.namespace :foo do
          register(:bar) { "baz" }
        end
      }.to yield_with_args("foo.bar")
    end
  end

  describe "after_finalize hook" do
    it "executes after finalization" do
      expect { |hook|
        system.after(:finalize, &hook)
        system.finalize!
      }.to yield_control
    end

    it "executes before the container is frozen" do
      is_frozen = nil

      system.after(:finalize) { is_frozen = frozen? }
      system.finalize!

      expect(is_frozen).to eq false
      expect(system).to be_frozen
    end
  end
end
