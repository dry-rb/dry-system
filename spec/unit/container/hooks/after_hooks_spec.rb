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
  end
end
