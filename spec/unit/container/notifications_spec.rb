# frozen_string_literal: true

RSpec.describe Dry::System::Container do
  subject(:system) do
    Class.new(Dry::System::Container) do
      use :notifications
    end
  end

  describe '.notifications' do
    it 'returns configured notifications' do
      system.configure {}

      expect(system[:notifications]).to be_instance_of(Dry::Monitor::Notifications)
    end
  end
end
