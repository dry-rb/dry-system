# frozen_string_literal: true

require "dry/system/auto_registrar/configuration"

RSpec.describe Dry::System::AutoRegistrar::Configuration do
  subject(:auto_registration_conf) { Dry::System::AutoRegistrar::Configuration.new }

  describe "deafult values" do
    it "will setup exclude default proc" do
      expect(subject.exclude.(8)).to eq false
    end

    it "will setup instance default proc" do
      component = double("component")
      expect(component).to receive(:instance)
      subject.instance.(component)
    end
  end

  describe "add custom proc object to configuration" do
    it "execute proc that was previously save" do
      proc = proc { |value| value + 1 }
      subject.instance(&proc)
      result = subject.instance.(5)
      expect(result).to eq 6
    end
  end
end
