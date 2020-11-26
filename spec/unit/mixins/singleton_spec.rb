# frozen_string_literal: true

require "dry/system/mixins/singleton"

RSpec.describe Dry::System::Mixins::Singleton do
  describe ".instance" do
    it "returns the same instance when included into a class" do
      class Subject
        include Dry::System::Mixins::Singleton
      end

      subject_instance = Subject.instance
      expect(subject_instance).to eq(Subject.instance)
      expect(subject_instance).not_to eq(Subject.new)
    end
  end
end
