# frozen_string_literal: true

require 'delegate'

RSpec.describe Dry::System::Container do
  subject(:system) do
    Class.new(Dry::System::Container)
  end

  describe '.decorate' do
    it 'decorates registered singleton object with provided decorator API' do
      system.register(:foo, 'foo')

      system.decorate(:foo, with: SimpleDelegator)

      expect(system[:foo]).to be_instance_of(SimpleDelegator)
    end

    it 'decorates registered object with provided decorator API' do
      system.register(:foo) { 'foo' }

      system.decorate(:foo, with: SimpleDelegator)

      expect(system[:foo]).to be_instance_of(SimpleDelegator)
      expect(system[:foo].__getobj__).to eql('foo')
    end
  end
end
