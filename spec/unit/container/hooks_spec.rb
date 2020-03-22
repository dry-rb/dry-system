# frozen_string_literal: true

RSpec.describe Dry::System::Container do
  subject(:system) do
    Class.new(Dry::System::Container)
  end

  describe ".after" do
    it "registers an after hook" do
      system.after(:configure) do
        register(:test, true)
      end

      system.configure {}

      expect(system[:test]).to be(true)
    end

    it "inherits hooks from superclass" do
      system.after(:configure) do
        register(:test_1, true)
      end

      descendant = Class.new(system) do
        after(:configure) do
          register(:test_2, true)
        end
      end

      descendant.configure {}

      expect(descendant[:test_1]).to be(true)
      expect(descendant[:test_2]).to be(true)
    end
  end
end
