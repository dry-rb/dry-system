# frozen_string_literal: true

require "dry/system/loader/autoloading"
require "dry/system/component"

RSpec.describe Dry::System::Loader::Autoloading do
  describe "#require!" do
    subject(:loader) { described_class }
    let(:component) { Dry::System::Component.new("test.not_loaded_const") }

    before do
      allow(loader).to receive(:require)
      allow(Test).to receive(:const_missing)
    end

    it "loads the constant " do
      loader.require!(component)
      expect(loader).not_to have_received(:require)
      expect(Test).to have_received(:const_missing).with :NotLoadedConst
    end

    it "returns self" do
      expect(loader.require!(component)).to eql loader
    end
  end
end
