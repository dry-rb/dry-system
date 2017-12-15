RSpec.describe Dry::System::Container do
  subject(:system) do
    Class.new(Dry::System::Container)
  end

  describe '.after' do
    it 'registers an after hook' do
      system.after(:configure) do
        register(:test, true)
      end

      system.configure { }

      expect(system[:test]).to be(true)
    end
  end
end
